output "codepipeline_bucket_name" {
  description = "The name of the S3 bucket for CodePipeline artifacts."
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}

output "codepipeline_name" {
  description = "The name of the CodePipeline."
  value       = aws_codepipeline.main.name
}