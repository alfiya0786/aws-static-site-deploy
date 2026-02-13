

# Create S3 bucket
resource "aws_s3_bucket" "s3-bucket" {
  bucket = var.bucket_name
}

# Make S3 bucket Privet
resource "aws_s3_bucket_public_access_block" "public-access-block" {
  bucket = aws_s3_bucket.s3-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# origin access control for cloudfront 
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "Static-Website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "allow-access-cf" {
  bucket = aws_s3_bucket.s3-bucket.id
  depends_on = [ aws_s3_bucket_public_access_block.public-access-block ]

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement" : [
    {
      "Sid": "AllowCloudFront",
      "Effect": "Allow",
      "Principal": {
        Service : "cloudfront.amazonaws.com"
      },
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "${aws_s3_bucket.s3-bucket.arn}/*"
       Condition : {
        StringEquals : {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
        }
       }
    }
  ] 
  })
}

# Upload file on s3
resource "aws_s3_object" "object" {
  
  for_each = fileset("${path.module}/www","**/*")
  bucket = aws_s3_bucket.s3-bucket.id
  key    = "www/${each.value}"
  source = "${path.module}/www/${each.value}"
  etag = filemd5("${path.module}/www/${each.value}")
  
  content_type = lookup({
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "json" = "application/json",
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "gif"  = "image/gif",
    "svg"  = "image/svg+xml",
    "ico"  = "image/x-icon",
    "txt"  = "text/plain"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

# # upload error page file to S3 
resource "aws_s3_object" "error-page" {
  
  for_each = fileset("${path.module}/error","**/*")
  bucket = aws_s3_bucket.s3-bucket.id
  key    = "error/${each.value}"
  source = "${path.module}/error/${each.value}"
  etag = filemd5("${path.module}/error/${each.value}")
  
  content_type = lookup({
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "json" = "application/json",
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "gif"  = "image/gif",
    "svg"  = "image/svg+xml",
    "ico"  = "image/x-icon",
    "txt"  = "text/plain"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

# Create CF Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.s3-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.origin_id
    origin_path = "/www"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"  # cloud front serve from edge location only US and Europe 

  restrictions {
    geo_restriction {
      restriction_type = "none"  # Global access of content
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_code = 403
    response_page_path = "/error/403.html"
    response_code = 403
    error_caching_min_ttl = 60
  }

  custom_error_response {
    error_code = 404
    response_page_path = "/error/404.html"
    response_code = 404
    error_caching_min_ttl = 60

  }

}

