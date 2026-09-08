resource "aws_bedrockagent_data_source" "documents" {
  name              = "${var.project_name}-datasource"
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.documents.arn
    }
  }
  data_deletion_policy = "RETAIN"
  depends_on = [
    aws_s3_object.aws,
    aws_s3_object.terraform,
    aws_s3_object.bedrock
  ]
}
