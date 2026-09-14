data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_s3_bucket" "resume" {
  bucket_prefix = "cloud-resume-"

  tags = {
    Project   = "cloud-resume"
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "resume" {
  bucket = aws_s3_bucket.resume.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "resume" {
  name                              = "cloud-resume-oac"
  description                       = "OAC for the private cloud resume S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "resume" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.resume.bucket_regional_domain_name
    origin_id                = "resume-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.resume.id
  }

  default_cache_behavior {
    target_origin_id       = "resume-s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project   = "cloud-resume"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "resume_bucket" {
  statement {
    sid = "AllowCloudFrontServicePrincipalReadOnly"

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.resume.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.resume.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "resume" {
  bucket = aws_s3_bucket.resume.id
  policy = data.aws_iam_policy_document.resume_bucket.json
}

resource "aws_dynamodb_table" "visitor_counter" {
  name         = "cloud-resume-visitor-counter"
  billing_mode = "PROVISIONED"

  read_capacity  = 1
  write_capacity = 1

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project   = "cloud-resume"
    ManagedBy = "terraform"
  }
}


data "archive_file" "visitor_counter" {
  type        = "zip"
  source_file = "${path.module}/../lambda/visitor_counter.py"
  output_path = "${path.module}/visitor_counter.zip"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "visitor_counter" {
  name               = "cloud-resume-visitor-counter-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Project   = "cloud-resume"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "visitor_counter_lambda" {
  statement {
    sid = "UpdateVisitorCounter"

    actions = [
      "dynamodb:UpdateItem",
    ]

    resources = [
      aws_dynamodb_table.visitor_counter.arn,
    ]
  }

  statement {
    sid = "WriteLambdaLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*",
    ]
  }
}

resource "aws_iam_role_policy" "visitor_counter" {
  name   = "cloud-resume-visitor-counter"
  role   = aws_iam_role.visitor_counter.id
  policy = data.aws_iam_policy_document.visitor_counter_lambda.json
}

resource "aws_lambda_function" "visitor_counter" {
  function_name = "cloud-resume-visitor-counter"

  role    = aws_iam_role.visitor_counter.arn
  handler = "visitor_counter.handler"
  runtime = "python3.13"

  filename         = data.archive_file.visitor_counter.output_path
  source_code_hash = data.archive_file.visitor_counter.output_base64sha256

  memory_size = 128
  timeout     = 3

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_counter.name
    }
  }

  tags = {
    Project   = "cloud-resume"
    ManagedBy = "terraform"
  }
}


resource "aws_apigatewayv2_stage" "visitor_counter" {
  api_id = aws_apigatewayv2_api.visitor_counter.id

  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_counter.execution_arn}/*/*"
}

resource "aws_apigatewayv2_api" "visitor_counter" {
  name          = "cloud-resume-visitor-counter"
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["GET"]
    allow_origins = ["*"]
  }

  tags = {
    Project   = "cloud-resume"
    ManagedBy = "terraform"
  }
}

resource "aws_apigatewayv2_integration" "visitor_counter" {
  api_id = aws_apigatewayv2_api.visitor_counter.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_counter.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "visitor_counter" {
  api_id = aws_apigatewayv2_api.visitor_counter.id

  route_key = "GET /count"
  target    = "integrations/${aws_apigatewayv2_integration.visitor_counter.id}"
}

