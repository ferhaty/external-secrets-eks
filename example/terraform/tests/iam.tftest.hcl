mock_provider "aws" {}

override_resource {
  target = aws_iam_role.reader
  values = { arn = "arn:aws:iam::111122223333:role/shop-secrets-demo-reader" }
}

override_resource {
  target = aws_secretsmanager_secret.demo
  values = {
    arn = "arn:aws:secretsmanager:us-east-1:111122223333:secret:shop/demo/checkout-AbCdEf"
    id  = "arn:aws:secretsmanager:us-east-1:111122223333:secret:shop/demo/checkout-AbCdEf"
  }
}

variables {
  aws_region        = "us-east-1"
  aws_account_id    = "111122223333"
  oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE123"
}

run "scoped_read_and_trust" {
  command = apply
  assert {
    condition     = jsondecode(aws_iam_role_policy.reader.policy).Statement[0].Resource == aws_secretsmanager_secret.demo.arn && length(jsondecode(aws_iam_role_policy.reader.policy).Statement) == 1
    error_message = "The default policy must target only the created secret's exact ARN."
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.reader.policy).Statement[0].Action == ["secretsmanager:GetSecretValue"]
    error_message = "No discovery or write permissions for ESO."
  }
  assert {
    condition     = jsondecode(aws_iam_role.reader.assume_role_policy).Statement[0].Condition.StringEquals["${local.oidc_issuer}:sub"] == "system:serviceaccount:shop-secrets-demo:checkout-secret-reader" && jsondecode(aws_iam_role.reader.assume_role_policy).Statement[0].Condition.StringEquals["${local.oidc_issuer}:aud"] == "sts.amazonaws.com"
    error_message = "Trust must bind one namespace/service account and STS audience."
  }
  assert {
    condition     = aws_secretsmanager_secret_version.demo.secret_id == aws_secretsmanager_secret.demo.id && jsondecode(aws_secretsmanager_secret_version.demo.secret_string).apiKey == "demo-only-v1"
    error_message = "Terraform must create the JSON dummy value in its own demo secret."
  }
  assert {
    condition     = aws_secretsmanager_secret.demo.kms_key_id == null && aws_secretsmanager_secret.demo.recovery_window_in_days == 30
    error_message = "Default encryption is AWS managed; deletion retains the normal recovery window."
  }
  assert {
    condition     = output.secret_arn == aws_secretsmanager_secret.demo.arn && !strcontains(output.secret_arn, "*")
    error_message = "Export the actual full secret ARN without a wildcard."
  }
}

run "update_dummy_value_plan" {
  command = plan
  variables { demo_api_key = "demo-only-v2" }
  assert {
    condition     = jsondecode(aws_secretsmanager_secret_version.demo.secret_string).apiKey == "demo-only-v2" && output.secret_arn == run.scoped_read_and_trust.secret_arn
    error_message = "A value update must retain the same secret and change its managed version."
  }
}

run "update_dummy_value_apply" {
  command = apply
  variables { demo_api_key = "demo-only-v2" }
  assert {
    condition     = jsondecode(aws_secretsmanager_secret_version.demo.secret_string).apiKey == "demo-only-v2" && output.secret_arn == run.scoped_read_and_trust.secret_arn
    error_message = "The second dummy value must be managed by Terraform in the same secret."
  }
}

run "customer_key" {
  command = plan
  variables {
    kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  }
  assert {
    condition     = aws_secretsmanager_secret.demo.kms_key_id == var.kms_key_arn && length(jsondecode(aws_iam_role_policy.reader.policy).Statement) == 2 && jsondecode(aws_iam_role_policy.reader.policy).Statement[1].Resource == var.kms_key_arn && jsondecode(aws_iam_role_policy.reader.policy).Statement[1].Condition.StringEquals["kms:EncryptionContext:SecretARN"] == aws_secretsmanager_secret.demo.arn && jsondecode(aws_iam_role_policy.reader.policy).Statement[1].Condition.StringEquals["kms:ViaService"] == "secretsmanager.us-east-1.amazonaws.com"
    error_message = "Encrypt with the selected key and scope decrypt to that key, service and secret."
  }
}

run "foreign_oidc_rejected" {
  command = plan
  variables {
    oidc_provider_arn = "arn:aws:iam::444455556666:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/OTHER"
  }
  expect_failures = [aws_iam_role.reader]
}

run "wrong_oidc_region_rejected" {
  command = plan
  variables {
    oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/OTHER"
  }
  expect_failures = [aws_iam_role.reader]
}

run "malformed_account_rejected" {
  command = plan
  variables { aws_account_id = "11112222333" }
  expect_failures = [var.aws_account_id]
}

run "wildcard_key_rejected" {
  command = plan
  variables { kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/*" }
  expect_failures = [var.kms_key_arn]
}

run "foreign_key_rejected" {
  command = plan
  variables { kms_key_arn = "arn:aws:kms:us-east-1:444455556666:key/00000000-0000-0000-0000-000000000000" }
  expect_failures = [aws_iam_role.reader]
}

run "role_output" {
  command = apply
  assert {
    condition     = output.reader_role_arn == "arn:aws:iam::111122223333:role/shop-secrets-demo-reader"
    error_message = "Output must wire through the mocked role ARN."
  }
}
