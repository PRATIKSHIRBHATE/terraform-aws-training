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
      Principal = [aws_iam_role.bedrock_kb.arn]
    }
  ])
  depends_on = [aws_opensearchserverless_security_policy.encryption]
}

resource "aws_opensearchserverless_collection" "vector" {
  name = "${var.project_name}-collection"
  type = "VECTORSEARCH"
  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.access
  ]
}
