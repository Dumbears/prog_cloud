output "bucket_id" {
  description = "Le nom (ID) du bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "L'ARN du bucket (utile pour les permissions IAM)"
  value       = aws_s3_bucket.this.arn
}