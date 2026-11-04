export AWS_REGION=us-east-1
export EKS_CONTEXT=YOUR_EXISTING_EKS_CONTEXT
export SECRET_ARN=arn:aws:secretsmanager:us-east-1:111122223333:secret:shop/demo/checkout-AbCdEf
aws sts get-caller-identity
kubectl --context "$EKS_CONTEXT" cluster-info
helm list --all-namespaces --kube-context "$EKS_CONTEXT"
kubectl --context "$EKS_CONTEXT" get namespaces shop-secrets-demo eso-shop-system
