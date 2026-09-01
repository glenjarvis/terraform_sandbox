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
  function_name = "hello_world"
}

# Zip src/ at plan time so there is no manual packaging step.
data "archive_file" "hello_world" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/hello_world.zip"
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

resource "aws_iam_role" "hello_world" {
  name               = "${local.function_name}_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# The only permission this function needs: write its own logs.
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.hello_world.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Declared explicitly (rather than letting Lambda auto-create it) so that
# retention is bounded and `terraform destroy` actually removes the logs.
resource "aws_cloudwatch_log_group" "hello_world" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "hello_world" {
  function_name = local.function_name
  role          = aws_iam_role.hello_world.arn

  filename         = data.archive_file.hello_world.output_path
  source_code_hash = data.archive_file.hello_world.output_base64sha256

  runtime = "python3.13"
  handler = "hello_world.handler"

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution,
    aws_cloudwatch_log_group.hello_world,
  ]
}
