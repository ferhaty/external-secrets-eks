terraform -chdir=terraform apply reader.tfplan
terraform -chdir=terraform output -raw reader_role_arn
