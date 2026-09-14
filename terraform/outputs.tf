output "aws_account_id" {
  description = "AWS account Terraform authenticated against."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_principal_arn" {
  description = "AWS principal Terraform authenticated as."
  value       = data.aws_caller_identity.current.arn
}

output "aws_region" {
  description = "AWS region selected by the provider."
  value       = data.aws_region.current.region
}

output "resume_bucket_name" {
  description = "Private S3 bucket used as the resume origin."
  value       = aws_s3_bucket.resume.bucket
}

output "cloudfront_domain_name" {
  description = "CloudFront hostname for the resume site."
  value       = aws_cloudfront_distribution.resume.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for the resume site."
  value       = aws_cloudfront_distribution.resume.id
}
