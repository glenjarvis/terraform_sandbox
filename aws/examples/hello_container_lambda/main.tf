terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # Local state - this example is small enough to create and destroy freely.
}

provider "aws" {
  region = "us-west-2"
}

locals {
  function_name = "hello_container"

  # Declared once so the image build and the function's declared
  # architecture cannot drift apart, same reasoning as requests_lambda.
  architecture = "x86_64"
}

# Holds the built image. Lambda pulls from here, not from a public registry.
resource "aws_ecr_repository" "hello_container" {
  name = local.function_name

  # Deleting the repo also deletes any images still in it - matches this
  # example's throwaway, local-state style.
  force_delete = true
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

resource "aws_iam_role" "hello_container" {
  name               = "${local.function_name}_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.hello_container.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "hello_container" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "hello_container" {
  function_name = local.function_name
  role          = aws_iam_role.hello_container.arn

  package_type  = "Image"
  architectures = [local.architecture]
  # :latest here is fine for this example; a production setup would pin to
  # a specific digest so a new push can't silently change what's deployed.
  image_uri = "${aws_ecr_repository.hello_container.repository_url}:latest"

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution,
    aws_cloudwatch_log_group.hello_container,
  ]
}
