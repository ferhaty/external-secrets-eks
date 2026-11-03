kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo describe secretstore checkout-aws
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo describe externalsecret checkout-credentials
kubectl --context "$EKS_CONTEXT" -n eso-shop-system logs deployment/eso-shop --tail=80
