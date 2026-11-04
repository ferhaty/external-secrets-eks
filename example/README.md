# EKS External Secrets walkthrough

Companion sample for [Turing Technology Services blog](https://blog.turingts.com/). See the [repository README](../README.md) for prerequisites, local checks and upstream references.

Run the commands from this directory in one terminal so exported variables remain available. Execute commands individually and stop on failure; the numbered files are separate snippets, not a batch deployment script.

## Configuration and sequence

1. `commands/01-context.sh`: replace `EKS_CONTEXT` and `SECRET_ARN`, then inspect the AWS identity, Kubernetes context, ESO installation and namespace ownership. The fixed namespaces are `shop-secrets-demo` and `eso-shop-system`; stop if they already exist without established ownership. Coordinate any existing ESO installation or shared CRDs with the administrator.
2. `commands/02-iam-plan.sh`: copy `terraform/terraform.tfvars.example`, then edit the copied file **before** initialization and planning. Set the intended account, region, existing OIDC provider and full source-secret ARN. Terraform owns only the reader IAM role and inline policy. Check that the fixed role name is available. If using a customer-managed KMS key, set its ARN and ensure its key policy permits the role.
3. Inspect the saved IAM plan, then run `commands/03-iam-apply.sh` separately. Use the resulting role ARN in `store.yaml`; set its region and the full secret ARN in `externalsecret.yaml` to match the Terraform inputs and `SECRET_ARN`.
4. `commands/04-seed.sh`: the secret owner writes the public dummy value to the approved, dedicated demo secret. This makes a new version current; never target a live service credential. Keep this write permission separate from ESO's reader role.
5. `namespaces.yaml`, `eso-values.yaml`, `commands/05-install.sh`: create the dedicated namespaces and install the scoped ESO controller. The manifests use `external-secrets.io/v1`.
6. `store.yaml`, `externalsecret.yaml`, `commands/06-store.sh`: apply the reader service account, scoped TokenRequest permission, namespaced store and explicit property mapping. Controller, reader and application service accounts are separate identities. Other RBAC bindings can grant broader access.
7. `consumer.yaml`, `commands/07-consumer.sh`: start the BusyBox consumption probe and compare its mounted file with its environment variable without printing either value.
8. `commands/08-rotate.sh` through `10-restart.sh`: write the second public dummy value, observe file/environment differences and replace the Pod. Allow ESO refresh and kubelet projection time before retrying a comparison. An existing Ready condition does not establish that the new version has arrived; the comparison checks the expected dummy version explicitly.
9. `commands/11-diagnose.sh`: inspect conditions and bounded controller logs. Redact identifiers and any sensitive content before sharing diagnostics.

## Cleanup

Use `commands/12-cleanup.sh` only for dedicated resources created by this walkthrough. It removes the consumer, ExternalSecret, store/reader identity and Helm release, waits for the owned Kubernetes Secret to disappear, and prepares an IAM destroy plan. Inspect that plan before running `commands/13-cleanup-apply.sh` separately.

CRDs are retained with `helm.sh/resource-policy: keep`; namespaces remain for administrator inspection. Do not delete shared dependencies. Retained CRDs need explicit ownership/adoption handling before reinstalling. The AWS source secret, optional KMS key, EKS cluster and OIDC provider remain unchanged by cleanup.

Keep `.terraform.lock.hcl` with the configuration. Never commit state, saved plans, credential files, local variable files or real secret values. Adjust dependency pins deliberately when maintaining your own copy.
