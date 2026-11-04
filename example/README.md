# EKS External Secrets walkthrough

Companion sample for [Turing Technology Services blog](https://blog.turingts.com/). See the [repository README](../README.md) for prerequisites, local checks and upstream references.

Run the commands from this directory in one terminal so exported variables remain available. Execute commands individually and stop on failure; the numbered files are separate snippets, not a batch deployment script.

## Configuration and sequence

1. `commands/01-context.sh`: replace `EKS_CONTEXT`, then inspect the AWS identity, Kubernetes context, ESO installation and namespace ownership. The fixed namespaces are `shop-secrets-demo` and `eso-shop-system`; stop if they already exist without established ownership. Coordinate any existing ESO installation or shared CRDs with the administrator.
2. `commands/02-iam-plan.sh`: copy `terraform/terraform.tfvars.example`, then edit the copied file **before** initialization and planning. Set the intended account, region and existing OIDC provider; keep `demo_api_key = "demo-only-v1"`. Terraform creates the dedicated secret, its JSON dummy value, the reader IAM role and inline policy. The deployment identity needs create, read (including `secretsmanager:GetSecretValue`), update and delete permissions for these demo resources. Check that the fixed secret and role names are available. If using a customer-managed KMS key, set its ARN and allow the deployment identity to encrypt and decrypt through Secrets Manager, and the reader role to decrypt.
3. Inspect the saved Terraform plan, then run `commands/03-iam-apply.sh` separately. Use the resulting role ARN in `store.yaml`; set its region to match Terraform and replace `remoteRef.key` in `externalsecret.yaml` with the exported `SECRET_ARN`, including its generated suffix.
4. `namespaces.yaml`, `eso-values.yaml`, `commands/05-install.sh`: create the dedicated namespaces and install the scoped ESO controller. The manifests use `external-secrets.io/v1`.
5. `store.yaml`, `externalsecret.yaml`, `commands/06-store.sh`: apply the reader service account, scoped TokenRequest permission, namespaced store and explicit property mapping. Controller, reader and application service accounts are separate identities. Other RBAC bindings can grant broader access.
6. `consumer.yaml`, `commands/07-consumer.sh`: start the BusyBox consumption probe and compare its mounted file with its environment variable without printing either value.
7. `commands/08-rotate.sh` through `10-restart.sh`: change `demo_api_key` to `"demo-only-v2"` in `terraform/terraform.tfvars`, plan with `08-rotate.sh`, inspect the plan, and apply separately with `08-rotate-apply.sh`. Then observe file/environment differences and replace the Pod. Terraform creates a new current version; do not update the value outside Terraform. Allow ESO refresh and kubelet projection time before retrying a comparison. An existing Ready condition does not establish that the new version has arrived; the comparison checks the expected dummy version explicitly.
8. `commands/11-diagnose.sh`: inspect conditions and bounded controller logs. Redact identifiers and any sensitive content before sharing diagnostics.

## Cleanup

Use `commands/12-cleanup.sh` only for dedicated resources created by this walkthrough. It removes the consumer, ExternalSecret, store/reader identity and Helm release, waits for the owned Kubernetes Secret to disappear, and prepares a destroy plan for the demo secret, managed version and reader IAM resources. Inspect that plan before running `commands/13-cleanup-apply.sh` separately.

CRDs are retained with `helm.sh/resource-policy: keep`; namespaces remain for administrator inspection. Do not delete shared dependencies. Retained CRDs need explicit ownership/adoption handling before reinstalling. The AWS source secret is scheduled for deletion with a 30-day recovery window. Its name cannot be reused until deletion completes; choose a different demo name to repeat sooner. Removing only the version resource does not delete the current secret value. The optional KMS key, EKS cluster and OIDC provider remain unchanged by cleanup.

Keep `.terraform.lock.hcl` with the configuration. The public dummy value is stored in Terraform state. Never commit state, saved plans, credential files, local variable files or real secret values. Adjust dependency pins deliberately when maintaining your own copy.
