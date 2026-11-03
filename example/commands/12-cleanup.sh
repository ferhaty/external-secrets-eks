# Only for the dedicated example resources created by this walkthrough.
kubectl --context "$EKS_CONTEXT" delete -f consumer.yaml
kubectl --context "$EKS_CONTEXT" delete -f externalsecret.yaml
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo wait   --for=delete secret/checkout-credentials --timeout=120s
kubectl --context "$EKS_CONTEXT" delete -f store.yaml
helm uninstall eso-shop --namespace eso-shop-system --kube-context "$EKS_CONTEXT"
terraform -chdir=terraform plan -destroy -out=cleanup.tfplan
