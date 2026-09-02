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
  layer_name = "requests"
}

# Zips what build_layer.sh staged. source_dir is build/ rather than
# build/python/ because archive_file places the *contents* of source_dir at
# the zip root, and Lambda requires python/ to be the top-level directory.
#
# The output lands in dist/, not build/: writing the zip inside its own
# source directory would make the archive's input change every time it runs.
data "archive_file" "layer" {
  type        = "zip"
  source_dir  = "${path.module}/build"
  output_path = "${path.module}/dist/${local.layer_name}_layer.zip"
}

resource "aws_lambda_layer_version" "requests" {
  layer_name = local.layer_name

  filename         = data.archive_file.layer.output_path
  source_code_hash = data.archive_file.layer.output_base64sha256

  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["x86_64"]

  description = "requests and its dependencies, built for the Lambda x86_64 runtime"
}
