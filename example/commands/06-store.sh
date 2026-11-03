kubectl --context "$EKS_CONTEXT" apply -f store.yaml
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo wait   --for=condition=Ready secretstore/checkout-aws --timeout=120s
kubectl --context "$EKS_CONTEXT" apply -f externalsecret.yaml
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo wait   --for=condition=Ready externalsecret/checkout-credentials --timeout=180s
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo get externalsecret checkout-credentials
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo get secret checkout-credentials
