################### S3 ######################

# create the bare domain S3 bucket

resource "aws_s3_bucket" "bare-domain" {
  bucket = var.domain
  acl    = "public-read"

  website {
    redirect_all_requests_to = "www.${var.domain}"
  }

  tags = {
    Name = "Managed by Terraform"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# create the www S3 bucket - web files are stored here

resource "aws_s3_bucket" "www-domain" {
  bucket = "www.${var.domain}"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags = {
    Name = "Managed by Terraform"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

################### Cloudfront ######################

# create the www Cloudfront distribution so the S3 static website uses HTTPS

resource "aws_cloudfront_distribution" "www_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = aws_s3_bucket.www-domain.website_endpoint
    origin_id   = "www.${var.domain}"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "www.${var.domain}"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "viewer-response"
      include_body = false
      lambda_arn   = aws_lambda_function.lambda.qualified_arn
    }
  }

  aliases = ["www.${var.domain}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
}

# create the bare domain Cloudfront distribution so the S3 static website uses HTTPS

resource "aws_cloudfront_distribution" "bare_domain_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = aws_s3_bucket.bare-domain.website_endpoint
    origin_id   = var.domain
  }

  enabled = true

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.domain
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "viewer-response"
      include_body = false
      lambda_arn   = aws_lambda_function.lambda.qualified_arn
    }
  }

  aliases = ["${var.domain}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }
}

################### Cloudfront Lambda@Edge ######################

# create a lambda to pass http security headers as part of the viewer response

resource "aws_lambda_function" "lambda" {
  function_name    = "cloudfront_headers"
  handler          = "index.handler"
  memory_size      = 128
  role             = aws_iam_role.lambda-role.arn
  runtime          = "nodejs12.x"
  filename         = "./files/index.js.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  publish          = true
  timeout          = 3

  tracing_config {
    mode = "PassThrough"
  }
}

# make terraform zip the lambda code so it can be pushed up to lambda

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "./files/index.js"
  output_path = "./files/index.js.zip"
}

################### Lambda IAM Role ############################

# create a role for the lambda to assume so it can run
# notice the edgelambda.amazonaws.com addition for allowing lambda@edge

resource "aws_iam_role" "lambda-role" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = [
              "edgelambda.amazonaws.com",
              "lambda.amazonaws.com",
            ]
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "cloudfront_headers-role-wy7mdbqc"
  path                  = "/service-role/"
}


################### Route53 ######################

# creates the hosted zone

resource "aws_route53_zone" "zone" {
  name = var.domain
}

# creates the dns record for the bare domain

resource "aws_route53_record" "bare-domain" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.bare_domain_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.bare_domain_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# creates the dns record for the www domain

resource "aws_route53_record" "www-domain" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "www.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.www_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.www_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

########################## ACM ########################

# manages the ACM certificate under terraform state
# note that the certificate is created outside of terraform
# and then imported into state due to restrictions on
# acm cert generation done throgh the cli

resource "aws_acm_certificate" "cert" {
  domain_name = "*.${var.domain}"
  subject_alternative_names = [
    "${var.domain}",
  ]
  validation_method = "DNS"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
}
