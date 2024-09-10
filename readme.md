# Terraform-EnvHelper

**Terraform-EnvHelper** is an open-source project designed to load environment variables from a `.env` file and pass them into Terraform. This tool is particularly useful for managing sensitive data like API keys, AWS credentials, and database passwords without hardcoding them in your Terraform configuration files.

## Key Features

- Load environment variables from a `.env` file for use in Terraform.
- Securely pass environment variables without hardcoding sensitive information.
- Works seamlessly on **Linux/Ubuntu** environments.

## Prerequisites

Make sure you have the following tools installed:

- **jq**: A lightweight and flexible command-line JSON processor.

  To install `jq` on Ubuntu, run:

```bash
sudo apt-get install jq
```

## Installation

To use Terraform-EnvHelper, follow these steps:

### 1. Clone the Repository

Clone the repository to your local machine and navigate into the project directory:

```bash
git clone https://github.com/your-username/Terraform-EnvHelper.git 
cd Terraform-EnvHelper`
```

### 2. Create Your `.env` File

Create a `.env` file in the root directory of the project and define your environment variables, such as:

```bash
AWS_ACCESS_KEY_ID=your_access_key 
AWS_SECRET_ACCESS_KEY=your_secret_key
DB_PASSWORD=your_db_password`
```

### 3. Run the Script and Apply Terraform

Run the provided `read_env.sh` script to load environment variables from the `.env` file, and then initialize and apply your Terraform configuration:

```bash
bash read_env.sh
terraform init terraform apply`
```

### How It Works

**Terraform-EnvHelper** uses the `external` data source in Terraform along with a shell script (`read_env.sh`) to load environment variables from the `.env` file. These environment variables are then passed into Terraform for use in your configurations, allowing you to keep sensitive data secure and out of your codebase.

Here’s the `read_env.sh` script used to load the environment variables:

```bash
#!/bin/bash
set -o allexport
source .env
set +o allexport

jq -n \
  --arg aws_access_key_id "$AWS_ACCESS_KEY_ID" \
  --arg aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" \
  --arg db_password "$DB_PASSWORD" \
  '{ aws_access_key_id: $aws_access_key_id, aws_secret_access_key: $aws_secret_access_key, db_password: $db_password }'

```

### Adding New Environment Variables

When adding new environment variables, you need to update **both** the `.env` file and the `read_env.sh` script:

1. **Update the** `.env` file with your new variable:

```bash
NEW_VARIABLE=new_value
```

2. **Update** `read_env.sh` to include the new variable:

```bash
jq -n \
  --arg aws_access_key_id "$AWS_ACCESS_KEY_ID" \
  --arg aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" \
  --arg db_password "$DB_PASSWORD" \
  --arg new_variable "$NEW_VARIABLE" \
  '{ aws_access_key_id: $aws_access_key_id, aws_secret_access_key: $aws_secret_access_key, db_password: $db_password, new_variable: $new_variable }'

```

By keeping both the `.env` file and the `read_env.sh` script in sync, you ensure that any newly added environment variables will be loaded and passed into Terraform.

### Example Use Case

Once the environment variables are loaded, you can use them in your Terraform configuration, for example:

```hcl
data "external" "env_vars" {
  program = ["bash", "./read_env.sh"]
}

output "aws_access_key_id" {
  value = data.external.env_vars.result.aws_access_key_id
}

output "db_password" {
  value = data.external.env_vars.result.db_password
}
```

## Why Use Terraform-EnvHelper?

- **Security**: Keep sensitive information like API keys and passwords out of your codebase.
- **Simplicity**: Automatically load environment variables from a `.env` file.
- **Linux Compatibility**: Works seamlessly on **Linux/Ubuntu** environments.

## License

Terraform-EnvHelper is licensed under the MIT License.


