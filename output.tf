output "website_url" {
  description = "The URL of the static website"
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}