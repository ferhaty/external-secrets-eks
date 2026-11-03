kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo rollout restart deployment/checkout-demo
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo rollout status deployment/checkout-demo --timeout=120s
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo exec deployment/checkout-demo -- sh -c '
  test "$CHECKOUT_API_KEY" = "demo-only-v2" &&
  test "$CHECKOUT_API_KEY" = "$(cat /run/checkout/api-key)" &&
  printf "Replacement Pod uses the new value in both paths.\n"
'
