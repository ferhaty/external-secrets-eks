# In terraform/terraform.tfvars, change demo_api_key from "demo-only-v1" to "demo-only-v2".
terraform -chdir=terraform plan -out=rotation.tfplan
