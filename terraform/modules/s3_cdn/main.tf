resource "aws_s3_bucket" "website-bucket" {
  bucket = var.bucket_name

  tags = var.tags
}

locals {
  s3_origin_id = "s3origin_id-${var.bucket_name}"
}

resource "aws_s3_bucket" "log-bucket" {
  bucket = "${var.bucket_name}-logs"

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "oc-logs" {
  bucket = aws_s3_bucket.log-bucket.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "aclLogs" {
  depends_on = [aws_s3_bucket_ownership_controls.oc-logs]

  bucket = aws_s3_bucket.log-bucket.id
  acl    = "log-delivery-write"
}

resource "aws_cloudfront_origin_access_control" "oacWebsite" {
  name                              = "OAC-${var.bucket_name}"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = [ aws_s3_bucket_acl.aclLogs, aws_cloudfront_origin_access_control.oacWebsite ]
  origin {
    domain_name              = aws_s3_bucket.website-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oacWebsite.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.log-bucket.bucket_domain_name
    prefix          = "logs"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = var.tags

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "allow_read_website" {
  bucket = aws_s3_bucket.website-bucket.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement":[{
        "Sid" : "AllowCloudFrontServicePrincipleReadOnly",
        "Effect" : "Allow",
        "Principal" : {
            "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.website-bucket.arn}/*"
        "Condition":{
            "StringEquals":{
                "AWS:SourceArn" : "arn:aws:cloudfront::734579227127:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
            }
        }
    }]
  })
}

resource "aws_s3_bucket_policy" "allow_write_logs" {
  bucket = aws_s3_bucket.log-bucket.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement":[{
        "Sid" : "AllowCloudFrontServiceWriteLogs",
        "Effect" : "Allow",
        "Principal" : {
            "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:*",
        "Resource": "${aws_s3_bucket.log-bucket.arn}/*"
        "Condition":{
            "StringEquals":{
                "AWS:SourceArn" : "arn:aws:cloudfront::734579227127:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
            }
        }
    }]
  })
}