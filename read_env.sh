#!/bin/bash
set -o allexport
source .env
set +o allexport

jq -n \
  --arg aws_access_key_id "$AWS_ACCESS_KEY_ID" \
  --arg aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" \
  --arg db_password "$DB_PASSWORD" \
  '{ aws_access_key_id: $aws_access_key_id, aws_secret_access_key: $aws_secret_access_key, db_password: $db_password }'
