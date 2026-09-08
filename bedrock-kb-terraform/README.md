# Deploy an Amazon Bedrock Knowledge Base Using Terraform

This project provisions the infrastructure for a Retrieval-Augmented Generation (RAG)
application using Terraform. Source documents flow into Amazon S3, then into a Bedrock
Knowledge Base, which creates vector embeddings and stores them in an OpenSearch
Serverless vector store for retrieval.

It uses the **customer-managed** approach with OpenSearch Serverless, so Terraform
provisions the vector store itself.

## Architecture

```
       +----------------------+
       |   Source Documents   |
       | PDF / TXT / MD / CSV |
       +-----------|----------+
                   | Data Source
                   v
         +------------------+
         |    Amazon S3     |
         | Documents Bucket |
         +---------|--------+
                   |
                   v
  +---------------------------------+
  |     Bedrock Knowledge Base      |
  | Chunking, Embeddings, Retrieval |
  +----------------|----------------+
                   |
                   v
       +-----------------------+
       | OpenSearch Serverless |
       |     Vector Store      |
       +-----------|-----------+
                   |
                   v
        +---------------------+
        |   RAG Application   |
        | Retrieve / Generate |
        +---------------------+
```

## Project Structure

```
bedrock-kb-terraform/
|
+-- provider.tf          # Terraform + AWS provider configuration
+-- variables.tf         # Input variables (region, project name)
+-- s3.tf                # S3 bucket, security settings, sample documents
+-- iam.tf               # IAM role and policy for Bedrock
+-- opensearch.tf        # OpenSearch Serverless policies, collection, vector index
+-- knowledge-base.tf    # Bedrock Knowledge Base
+-- data-source.tf       # S3 data source for the Knowledge Base
+-- outputs.tf           # Useful outputs (IDs, ARNs, bucket name)
+-- README.md
|
+-- documents/
    +-- aws.txt
    +-- terraform.txt
    +-- bedrock.txt
```

## Prerequisites

- AWS CLI
- Terraform >= 1.5
- An AWS account
- IAM permissions to create S3 buckets, IAM roles/policies, an OpenSearch Serverless
  collection, and a Bedrock Knowledge Base
- Access to the `amazon.titan-embed-text-v2:0` embedding model enabled in your account

Verify your tools and identity:

```bash
terraform version
aws --version
aws configure
aws sts get-caller-identity
```

## Region

This project defaults to `ap-south-1`. You can change it via the `aws_region` variable,
but make sure the embedding model and OpenSearch Serverless are available in that region.

## Vector index

A Bedrock Knowledge Base requires the vector index to **already exist** in the
OpenSearch Serverless collection before it is created. Creating the collection does not
create an index, so `opensearch.tf` creates the `bedrock-knowledge-base-index` index
(1024 dimensions for Titan Text Embeddings V2) using the `opensearch` provider, and the
Knowledge Base depends on it.

This also means Terraform uses three providers: `aws`, `opensearch` (to create the
index), and `time` (short waits so OpenSearch Serverless data-access permissions
propagate before the index and Knowledge Base are created). `terraform init` installs
all three.

## Deploy

```bash
terraform init
terraform validate
terraform fmt
terraform plan
terraform apply   # enter: yes
```

> OpenSearch Serverless and the Knowledge Base can take several minutes to finish creating.
> The configuration includes short deliberate waits (~90s total) so data-access
> permissions propagate before the index and Knowledge Base are created.

Check the outputs:

```bash
terraform output
```

## Verify in the AWS Console

After `terraform apply` succeeds, confirm the resources were created correctly in the
AWS Console. Make sure the console region (top-right) is set to the same region as your
deployment (`ap-south-1` by default).

### 1. S3 bucket and documents

- Go to **S3** > open the bucket named `bedrock-kb-lab-documents-...`.
- Confirm the three objects exist: `aws.txt`, `terraform.txt`, `bedrock.txt`.
- **Properties** tab: **Bucket Versioning** shows `Enabled`.
- **Permissions** tab: **Block all public access** is `On`.

### 2. IAM role and policy

- Go to **IAM** > **Roles** > open `bedrock-kb-lab-role`.
- **Trust relationships**: the trusted entity is `bedrock.amazonaws.com`.
- **Permissions**: an inline policy `bedrock-kb-lab-policy` is attached, granting S3
  read, `bedrock:InvokeModel`, and `aoss:APIAccessAll`.

### 3. OpenSearch Serverless collection

- Go to **Amazon OpenSearch Service** > **Serverless** > **Collections**.
- Open `bedrock-kb-lab-collection` and confirm:
  - **Status** is `Active` (it can take a few minutes to move from `Creating`).
  - **Type** is `Vector search`.
- Under **Security policies**, confirm the encryption, network, and data access policies
  exist (`bedrock-kb-lab-encryption`, `bedrock-kb-lab-network`, `bedrock-kb-lab-access`).

### 4. Bedrock Knowledge Base

- Go to **Amazon Bedrock** > **Knowledge Bases** > open `bedrock-kb-lab-kb`.
- Confirm:
  - **Status** is `Ready`.
  - **Service role** is `bedrock-kb-lab-role`.
  - **Embeddings model** is `Titan Text Embeddings V2` (`amazon.titan-embed-text-v2:0`).
  - **Vector store** points to the OpenSearch Serverless collection above.
- Under **Data source**, confirm `bedrock-kb-lab-datasource` exists and points to the
  S3 bucket. Its **sync status** will show as never synced / `Available` until you run
  the ingestion job (see below) — the initial `apply` does not ingest documents.

### 5. Model access

- Go to **Amazon Bedrock** > **Model access** and confirm `Titan Text Embeddings V2`
  is `Access granted`. If it is not, the ingestion job will fail with a model access
  error.

## Load and Test the Knowledge Base

Creating the Knowledge Base and data source does not automatically load your documents.
They still need to be ingested.

### 1. Verify the uploaded documents

```bash
aws s3 ls $(terraform output -raw s3_bucket_name)
```

Expected: `aws.txt`, `bedrock.txt`, `terraform.txt`

### 2. Start ingestion

```bash
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id $(terraform output -raw knowledge_base_id) \
  --data-source-id $(terraform output -raw data_source_id) \
  --region ap-south-1
```

Check its status and wait until it shows `COMPLETE`:

```bash
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id $(terraform output -raw knowledge_base_id) \
  --data-source-id $(terraform output -raw data_source_id) \
  --region ap-south-1
```

### 3. Test retrieval

```bash
aws bedrock-agent-runtime retrieve \
  --knowledge-base-id $(terraform output -raw knowledge_base_id) \
  --retrieval-configuration '{"vectorSearchConfiguration": {"numberOfResults": 5}}' \
  --retrieval-query '{"text": "What is Terraform?"}' \
  --region ap-south-1
```

### 4. Test retrieve-and-generate

Replace `YOUR_KB_ID` and `YOUR_MODEL_ARN` with your own values.

```bash
aws bedrock-agent-runtime retrieve-and-generate \
  --input '{"text": "Explain Terraform based on the knowledge base."}' \
  --retrieve-and-generate-configuration '{
    "type": "KNOWLEDGE_BASE",
    "knowledgeBaseConfiguration": {
      "knowledgeBaseId": "YOUR_KB_ID",
      "modelArn": "YOUR_MODEL_ARN"
    }
  }' \
  --region ap-south-1
```

## Outputs

| Output                      | Description                          |
| --------------------------- | ------------------------------------ |
| `s3_bucket_name`            | Name of the documents S3 bucket      |
| `knowledge_base_id`         | Bedrock Knowledge Base ID            |
| `knowledge_base_arn`        | Bedrock Knowledge Base ARN           |
| `data_source_id`            | S3 data source ID                    |
| `opensearch_collection_arn` | OpenSearch Serverless collection ARN |

## Troubleshooting

- **AccessDeniedException** — check the IAM role's S3, Bedrock, and OpenSearch permissions.
- **Model access denied** — confirm the embedding model is available in your region and
  enabled for your account.
- **Collection fails to create** — confirm the encryption and network policies exist
  before the collection is created.
- **Retrieval returns nothing** — check that the ingestion job status is `COMPLETE`,
  then try again.

## Clean Up

```bash
terraform destroy   # enter: yes
```

> The data source uses `data_deletion_policy = "RETAIN"`, so double-check the Bedrock
> console after destroying to confirm no vector data was left behind.

## Security Notes

This project is intended as a lab. For production:

- Narrow the IAM permissions instead of granting `Resource = "*"`. Only grant access to
  the specific bucket, model, and collection your application needs.
- Use a more restrictive OpenSearch Serverless network configuration instead of
  `AllowFromPublic = true`.
