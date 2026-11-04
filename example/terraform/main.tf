terraform {
  required_version = ">= 1.9.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.71.0"
    }
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "Use the intended 12-digit AWS account ID."
  }
}

variable "oidc_provider_arn" {
  description = "Existing IAM OIDC provider for this EKS cluster."
  type        = string
  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/oidc\\.eks\\.[a-z0-9-]+\\.amazonaws\\.com/id/[A-Za-z0-9]+$", var.oidc_provider_arn))
    error_message = "Use the existing EKS OIDC provider ARN, not its HTTPS issuer URL."
  }
}

variable "kms_key_arn" {
  description = "Optional customer-managed key ARN; null for aws/secretsmanager."
  type        = string
  default     = null
  validation {
    condition     = var.kms_key_arn == null ? true : can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[A-Za-z0-9-]+$", var.kms_key_arn))
    error_message = "Use a complete KMS key ARN, not an alias or wildcard."
  }
}

variable "demo_api_key" {
  description = "Public dummy value for the propagation exercise; never a real credential."
  type        = string
  default     = "demo-only-v1"
}

resource "aws_secretsmanager_secret" "demo" {
  name                    = "shop/demo/checkout"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 30
}

resource "aws_secretsmanager_secret_version" "demo" {
  secret_id     = aws_secretsmanager_secret.demo.id
  secret_string = jsonencode({ apiKey = var.demo_api_key })
}

locals {
  namespace       = "shop-secrets-demo"
  service_account = "checkout-secret-reader"
  oidc_issuer     = split("oidc-provider/", var.oidc_provider_arn)[1]
}

resource "aws_iam_role" "reader" {
  name = "shop-secrets-demo-reader"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
          "${local.oidc_issuer}:sub" = "system:serviceaccount:${local.namespace}:${local.service_account}"
        }
      }
    }]
  })
  lifecycle {
    precondition {
      condition = (
        split(":", var.oidc_provider_arn)[4] == var.aws_account_id &&
        startswith(local.oidc_issuer, "oidc.eks.${var.aws_region}.amazonaws.com/") &&
        (var.kms_key_arn == null ? true : startswith(var.kms_key_arn, "arn:aws:kms:${var.aws_region}:${var.aws_account_id}:key/"))
      )
      error_message = "OIDC provider and optional KMS key must belong to the intended account and region."
    }
  }
}

resource "aws_iam_role_policy" "reader" {
  name = "read-checkout-demo-secret"
  role = aws_iam_role.reader.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.demo.arn
      }
      ], var.kms_key_arn == null ? [] : [{
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.kms_key_arn
        Condition = {
          StringEquals = {
            "kms:ViaService"                  = "secretsmanager.${var.aws_region}.amazonaws.com"
            "kms:EncryptionContext:SecretARN" = aws_secretsmanager_secret.demo.arn
          }
        }
    }])
  })
}

output "secret_arn" {
  value = aws_secretsmanager_secret.demo.arn
}

output "reader_role_arn" {
  value = aws_iam_role.reader.arn
}
