kubectl --context "$EKS_CONTEXT" apply -f consumer.yaml
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo rollout status   deployment/checkout-demo --timeout=120s
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo exec deployment/checkout-demo -- sh -c '
  test -s /run/checkout/api-key &&
  test -n "$CHECKOUT_API_KEY" &&
  test "$CHECKOUT_API_KEY" = "$(cat /run/checkout/api-key)" &&
  printf "File and environment match; values not printed.\n"
'
