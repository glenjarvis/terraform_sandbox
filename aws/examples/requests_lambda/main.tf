terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  # Local state - this example is small enough to create and destroy freely.
}

provider "aws" {
  region = "us-west-2"
}

locals {
  function_name = "check_ip"

  # Declared once and used for both the function and the layer lookup, so
  # the two cannot drift apart.
  runtime      = "python3.13"
  architecture = "x86_64"
}

# The deployment package holds check_ip.py and nothing else. `requests`
# arrives from the layer at runtime.
data "archive_file" "check_ip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/dist/check_ip.zip"
}

# Look the layer up by name and take the current version, rather than
# hardcoding a version ARN that goes stale on the next publish.
#
# The compatibility filters matter: unfiltered, this resolves the newest
# version of the layer whether or not it fits. Publish a python3.12 build as
# :2 and the attach would fail with an error pointing at the function rather
# than at the lookup that picked wrong. Filtered, an unsatisfiable
# combination fails here instead, which is where the problem actually is.
#
# This also fails if no layer named "requests" exists in the region. That is
# the correct outcome: this example consumes a layer it does not own.
data "aws_lambda_layer_version" "requests" {
  layer_name              = "requests"
  compatible_runtime      = local.runtime
  compatible_architecture = local.architecture
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "check_ip" {
  name               = "${local.function_name}_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.check_ip.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "check_ip" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "check_ip" {
  function_name = local.function_name
  role          = aws_iam_role.check_ip.arn

  filename         = data.archive_file.check_ip.output_path
  source_code_hash = data.archive_file.check_ip.output_base64sha256

  runtime       = local.runtime
  handler       = "check_ip.handler"
  architectures = [local.architecture]

  # A versioned layer ARN. The layer must match the runtime and architecture
  # declared above, or the attach is rejected.
  layers = [data.aws_lambda_layer_version.requests.arn]

  # The 3-second default is tight for a cold start plus a TLS handshake.
  timeout = 10

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution,
    aws_cloudwatch_log_group.check_ip,
  ]
}
