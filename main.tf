# Use external data source to load secrets from .env file
data "external" "env_vars" {
  program = ["./read_env.sh"]
}

# Output the secrets (be careful, this will expose them in the output!)
output "aws_access_key_id" {
  value = data.external.env_vars.result.aws_access_key_id
}

output "db_password" {
  value = data.external.env_vars.result.db_password
}
