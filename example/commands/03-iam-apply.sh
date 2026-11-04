terraform -chdir=terraform apply reader.tfplan
terraform -chdir=terraform output -raw reader_role_arn
export SECRET_ARN=$(terraform -chdir=terraform output -raw secret_arn)
printf '%s\n' "$SECRET_ARN"
