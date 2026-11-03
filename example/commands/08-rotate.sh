# Same secret-owner path; do not give this write permission to ESO.
value_file=$(mktemp)
chmod 600 "$value_file"
printf '%s' '{"apiKey":"demo-only-v2"}' > "$value_file"
aws secretsmanager put-secret-value   --region "$AWS_REGION" --secret-id "$SECRET_ARN"   --secret-string "file://$value_file" --query VersionId --output text
rm -f "$value_file"
