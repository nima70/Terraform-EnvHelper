# Use external data source to load secrets from .env file
data "external" "env_vars" {
  program = ["./read_env.sh"]
}

# Example resource (you can replace this with any resource that needs the secrets)
# resource "null_resource" "example" {
#   provisioner "local-exec" {
#     command = <<EOT
#       echo "Using secrets from the .env file"
#       echo "AWS_ACCESS_KEY_ID: ${data.external.env_vars.result.aws_access_key_id}"
#       echo "AWS_SECRET_ACCESS_KEY: ${data.external.env_vars.result.aws_secret_access_key}"
#       echo "DB_PASSWORD: ${data.external.env_vars.result.db_password}"
#     EOT
#   }
# }

# Output the secrets (be careful, this will expose them in the output!)
output "aws_access_key_id" {
  value = data.external.env_vars.result.aws_access_key_id
}

output "db_password" {
  value = data.external.env_vars.result.db_password
}
