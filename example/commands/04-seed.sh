# Run as the secret owner against an approved, dedicated DEMO secret only.
# These are deliberately public dummy values, not credentials for a live service.
value_file=$(mktemp)
chmod 600 "$value_file"
printf '%s' '{"apiKey":"demo-only-v1"}' > "$value_file"
aws secretsmanager put-secret-value   --region "$AWS_REGION" --secret-id "$SECRET_ARN"   --secret-string "file://$value_file" --query VersionId --output text
rm -f "$value_file"
