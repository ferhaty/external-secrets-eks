kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo annotate   externalsecret checkout-credentials force-sync="$(date +%s)" --overwrite
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo get externalsecret checkout-credentials   -o jsonpath='{.status.refreshTime}{"\n"}{.status.conditions}{"\n"}'
kubectl --context "$EKS_CONTEXT" -n shop-secrets-demo exec deployment/checkout-demo -- sh -c '
  test "$(cat /run/checkout/api-key)" = "demo-only-v2" &&
  test "$CHECKOUT_API_KEY" = "demo-only-v1" &&
  printf "New file, old environment; no values printed.\n"
'
