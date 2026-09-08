output "s3_bucket_name" {
  value = aws_s3_bucket.documents.bucket
}

output "knowledge_base_id" {
  value = aws_bedrockagent_knowledge_base.this.id
}

output "knowledge_base_arn" {
  value = aws_bedrockagent_knowledge_base.this.arn
}

output "data_source_id" {
  value = aws_bedrockagent_data_source.documents.data_source_id
}

output "opensearch_collection_arn" {
  value = aws_opensearchserverless_collection.vector.arn
}
