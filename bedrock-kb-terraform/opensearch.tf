resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${var.project_name}-encryption"
  type = "encryption"
  policy = jsonencode({
    Rules = [
      {
        Resource     = ["collection/${var.project_name}-collection"]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.project_name}-network"
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          Resource     = ["collection/${var.project_name}-collection"]
          ResourceType = "collection"
        },
        {
          Resource     = ["collection/${var.project_name}-collection"]
          ResourceType = "dashboard"
        }
      ]
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_access_policy" "access" {
  name = "${var.project_name}-access"
  type = "data"
  policy = jsonencode([
    {
      Rules = [
        {
          Resource     = ["collection/${var.project_name}-collection"]
          ResourceType = "collection"
          Permission   = ["aoss:*"]
        },
        {
          Resource     = ["index/${var.project_name}-collection/*"]
          ResourceType = "index"
          Permission   = ["aoss:*"]
        }
      ]
      # Grant both Bedrock (to read/write embeddings) and the Terraform caller
      # (to create the vector index below) data access to the collection.
      Principal = [
        aws_iam_role.bedrock_kb.arn,
        data.aws_caller_identity.current.arn
      ]
    }
  ])
  depends_on = [aws_opensearchserverless_security_policy.encryption]
}

# Identity Terraform is running as; added to the access policy so it can
# create the vector index in the collection.
data "aws_caller_identity" "current" {}

resource "aws_opensearchserverless_collection" "vector" {
  name = "${var.project_name}-collection"
  type = "VECTORSEARCH"
  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.access
  ]
}

# OpenSearch Serverless data-access policy changes take time to propagate.
# Wait before creating the index so the index request is not rejected.
resource "time_sleep" "wait_for_data_access" {
  create_duration = "60s"
  depends_on = [
    aws_opensearchserverless_collection.vector,
    aws_opensearchserverless_access_policy.access
  ]
}

# The Bedrock Knowledge Base requires the vector index to already exist in the
# collection. Creating the collection does NOT create an index, so we create it
# here before the Knowledge Base. Titan Text Embeddings V2 produces 1024-dim
# vectors.
resource "opensearch_index" "vector" {
  name                           = "bedrock-knowledge-base-index"
  number_of_shards               = 2
  number_of_replicas             = 0
  index_knn                      = true
  index_knn_algo_param_ef_search = 512

  mappings = jsonencode({
    properties = {
      "bedrock-knowledge-base-default-vector" = {
        type      = "knn_vector"
        dimension = 1024
        method = {
          name       = "hnsw"
          engine     = "faiss"
          space_type = "l2"
          parameters = {
            ef_construction = 512
            m               = 16
          }
        }
      }
      "AMAZON_BEDROCK_TEXT_CHUNK" = {
        type = "text"
      }
      "AMAZON_BEDROCK_METADATA" = {
        type  = "text"
        index = false
      }
    }
  })

  force_destroy = true

  depends_on = [time_sleep.wait_for_data_access]
}

# Give the newly created index a moment to become available before the
# Knowledge Base tries to validate it.
resource "time_sleep" "wait_for_index" {
  create_duration = "30s"
  depends_on      = [opensearch_index.vector]
}
