mock_provider "aws" {}
variables {
  aws_region        = "eu-west-1"
  aws_account_id    = "111122223333"
  oidc_provider_arn = "arn:aws:iam::111122223333:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/EXAMPLE123"
  secret_arn        = "arn:aws:secretsmanager:eu-west-1:111122223333:secret:shop/demo/checkout-AbCdEf"
}
run "scoped_read_and_trust" {
  command = plan
  assert {
    condition     = jsondecode(aws_iam_role_policy.reader.policy).Statement[0].Resource == var.secret_arn && length(jsondecode(aws_iam_role_policy.reader.policy).Statement) == 1
    error_message = "The default policy must target only the specified secret."
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.reader.policy).Statement[0].Action[0] == "secretsmanager:GetSecretValue"
    error_message = "No broad discovery or write actions."
  }
  assert {
    condition     = jsondecode(aws_iam_role.reader.assume_role_policy).Statement[0].Condition.StringEquals["${local.oidc_issuer}:sub"] == "system:serviceaccount:shop-secrets-demo:checkout-secret-reader" && jsondecode(aws_iam_role.reader.assume_role_policy).Statement[0].Condition.StringEquals["${local.oidc_issuer}:aud"] == "sts.amazonaws.com"
    error_message = "Trust must bind one namespace/service account and STS audience."
  }
}
run "customer_key" {
  command = plan
  variables {
    kms_key_arn = "arn:aws:kms:eu-west-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  }
  assert {
    condition     = length(jsondecode(aws_iam_role_policy.reader.policy).Statement) == 2 && jsondecode(aws_iam_role_policy.reader.policy).Statement[1].Resource == var.kms_key_arn && jsondecode(aws_iam_role_policy.reader.policy).Statement[1].Condition.StringEquals["kms:EncryptionContext:SecretARN"] == var.secret_arn
    error_message = "Decrypt must bind the key and secret encryption context."
  }
}
run "foreign_oidc_rejected" {
  command = plan
  variables {
    oidc_provider_arn = "arn:aws:iam::444455556666:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/OTHER"
  }
  expect_failures = [aws_iam_role.reader]
}
run "wildcard_secret_rejected" {
  command = plan
  variables { secret_arn = "arn:aws:secretsmanager:eu-west-1:111122223333:secret:*" }
  expect_failures = [var.secret_arn]
}
run "mock_apply" {
  command = apply
  override_resource {
    target = aws_iam_role.reader
    values = { arn = "arn:aws:iam::111122223333:role/shop-secrets-demo-reader" }
  }
  assert {
    condition     = output.reader_role_arn == "arn:aws:iam::111122223333:role/shop-secrets-demo-reader"
    error_message = "Output must wire through the mocked role ARN."
  }
}
