# In terraform/main.tf, change the demo_api_key default from "demo-only-v1" to "demo-only-v2".
terraform -chdir=terraform plan -out=rotation.tfplan
