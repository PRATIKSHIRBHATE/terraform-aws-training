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
+-- opensearch.tf        # OpenSearch Serverless policies and collection
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

This project defaults to `us-east-1`. You can change it via the `aws_region` variable,
but make sure the embedding model and OpenSearch Serverless are available in that region.

## Deploy

```bash
terraform init
terraform validate
terraform fmt
terraform plan
terraform apply   # enter: yes
```

> OpenSearch Serverless and the Knowledge Base can take several minutes to finish creating.

Check the outputs:

```bash
terraform output
```

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
  --region us-east-1
```

Check its status and wait until it shows `COMPLETE`:

```bash
aws bedrock-agent list-ingestion-jobs \
  --knowledge-base-id $(terraform output -raw knowledge_base_id) \
  --data-source-id $(terraform output -raw data_source_id) \
  --region us-east-1
```

### 3. Test retrieval

```bash
aws bedrock-agent-runtime retrieve \
  --knowledge-base-id $(terraform output -raw knowledge_base_id) \
  --retrieval-configuration '{"vectorSearchConfiguration": {"numberOfResults": 5}}' \
  --retrieval-query '{"text": "What is Terraform?"}' \
  --region us-east-1
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
  --region us-east-1
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
