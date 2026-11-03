cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with the existing account, region, OIDC provider and secret ARN.
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform plan -out=reader.tfplan
