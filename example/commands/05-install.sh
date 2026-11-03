kubectl --context "$EKS_CONTEXT" create -f namespaces.yaml
helm repo add external-secrets https://charts.external-secrets.io
helm repo update external-secrets
helm install eso-shop external-secrets/external-secrets   --version 2.14.0 --namespace eso-shop-system   --kube-context "$EKS_CONTEXT" -f eso-values.yaml   --wait --timeout 5m
kubectl --context "$EKS_CONTEXT" wait   --for=condition=Established --timeout=120s   crd/secretstores.external-secrets.io crd/externalsecrets.external-secrets.io
