# External Secrets on EKS

Synchronize an AWS Secrets Manager value into Kubernetes with External Secrets Operator, a namespaced SecretStore and a scoped IRSA reader role. The sample includes Terraform, Helm values, Kubernetes manifests and command snippets for observing file and environment-variable updates.

[Turing Technology Services blog](https://blog.turingts.com/)

## Prerequisites

For local checks: Bash, Terraform >= 1.9 and < 2.0, and access to the locked AWS provider package. For the walkthrough: AWS CLI, kubectl, Helm 3, an existing EKS cluster with its IAM OIDC provider, an approved deployment identity with permission to create, read (including `secretsmanager:GetSecretValue`), update and delete the dedicated demo secret and its value version, and manage the reader IAM resources in the same AWS account and region. A customer-managed KMS key must allow the deployment identity to encrypt and decrypt through Secrets Manager, and the reader role to decrypt.

Confirm ownership of the fixed namespaces, IAM role and Helm release before creating anything. An existing ESO installation or shared CRDs need administrator coordination; RBAC permissions from other bindings remain additive.

## Layout

- [`example/README.md`](example/README.md): configuration and walkthrough sequence; run its commands from `example/`.
- `example/terraform/`: demo secret and public dummy value, reader role, scoped policy, dependency lock and mock-provider tests.
- `example/eso-values.yaml`: scoped controller and explicit CRD retention.
- `example/{namespaces,store,externalsecret,consumer}.yaml`: namespaces, IRSA reader identity, secret mapping and consumption probe.
- `example/commands/`: separate setup, observation and cleanup snippets. No GitHub Actions workflows are included.

## Local checks

From the repository root, this runs syntax checks and Terraform tests without AWS credentials. Provider initialization may download the locked package; the tests use `mock_provider "aws"`, including their mock apply.

```bash
(
  cd example || exit 1
  for script in commands/*.sh; do
    bash -n "$script" || exit 1
  done
  env -i PATH="$PATH" HOME="$HOME" \
    AWS_EC2_METADATA_DISABLED=true \
    AWS_SHARED_CREDENTIALS_FILE=/dev/null AWS_CONFIG_FILE=/dev/null \
    TF_CLI_CONFIG_FILE=/dev/null TF_INPUT=false TF_IN_AUTOMATION=true \
    bash --noprofile --norc -c '
      terraform -chdir=terraform init -input=false -lockfile=readonly &&
      terraform -chdir=terraform fmt -check -recursive &&
      terraform -chdir=terraform validate &&
      terraform -chdir=terraform test
    '
)
```

Local validation does not exercise AWS authorization, Kubernetes admission or live secret reconciliation.

## Usage and cleanup

Follow the [sample sequence](example/README.md) in one terminal, running commands individually and stopping on failure. Set the intended AWS identity and Kubernetes context, use the Terraform outputs for the reader-role and source-secret ARNs, and inspect each saved Terraform plan before its separate apply step. The `commands/` files contain live changes; do not execute them as a batch.

Use only the supplied public dummy values with the dedicated demo secret. Terraform stores the demo value in state. Keep real values, credentials, state, plans and local variable files out of Git; retain the provider lock. The consumer compares values without printing them. Allow time for ESO refresh and volume projection. Existing environment variables are not updated in place; restart the container or replace the Pod to receive the new value.

Cleanup removes the dedicated consumer, secret mapping, reader identity and Helm release, then prepares a destroy plan for the demo secret, managed version and IAM resources for inspection before apply. CRDs and namespaces remain for administrator inspection. The cluster, OIDC provider and optional KMS key are not created or deleted by this sample. Secret deletion uses a 30-day recovery window; its name cannot be reused until deletion completes. Choose another demo name to repeat sooner. Retained CRDs require explicit ownership decisions before a later installation.

## Upstream references

- [External Secrets: AWS Secrets Manager](https://external-secrets.io/latest/provider/aws-secrets-manager/)
- [External Secrets security guidance](https://external-secrets.io/latest/guides/security-best-practices/)
- [Chart release used by the sample](https://github.com/external-secrets/external-secrets/releases/tag/helm-chart-2.14.0)
- [AWS: associate an IAM role with a Kubernetes service account](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Terraform mock providers](https://developer.hashicorp.com/terraform/language/tests/mocking)
