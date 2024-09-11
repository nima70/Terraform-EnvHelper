# Terraform-EnvHelper

## Introduction

Have you grown tired of AWS Secrets Manager’s costs? Worried about exposing your secrets in your Terraform projects due to security concerns? Or perhaps you’re frustrated with managing multiple configuration files for different projects? Or for whatever reason, you are forced to keep your secrets only in a .env file? Why shouldn’t a typical .env file—something so familiar in other development workflows—work seamlessly in Terraform?

Look no further—Terraform-EnvHelper is here to solve these problems.

As you may already know, Terraform does not natively support .env files. Traditionally, the only way to manage secrets is to either expose them manually before running terraform init and terraform apply, or set the variables in the OS. But neither of these approaches is scalable:

- Manually exposing secrets is repetitive and error-prone.
- Setting environment variables in the OS can lead to conflicts between projects and clutter your environment.

That's why I created Terraform-EnvHelper—a simple yet powerful solution that allows you to use .env files with Terraform, making secret management easier, more secure, and more scalable.

## Why Not Use Simple `config.json` Files?

While using `config.json` files to manage your secrets and configurations may seem like a simple solution, environment variables offer significant advantages, especially when it comes to **CI/CD pipelines**. Here’s why environment variables are a better choice:

### Easier to Handle in CI/CD Pipelines
Most CI/CD tools and platforms are optimized for handling environment variables, allowing you to inject sensitive information dynamically during your deployment process. Configuring secrets through environment variables is often as simple as setting them in your CI/CD pipeline, eliminating the need to manage multiple JSON files across environments.

### Security
Injecting environment variables directly into the runtime during CI/CD is more secure than committing and pushing configuration files that might contain sensitive data. Even if the `config.json` file is ignored by version control, there’s always the risk of accidental exposure.

### Flexibility Across Environments
Environment variables allow you to easily switch between development, staging, and production environments without needing to create separate configuration files. This makes managing secrets across multiple environments much more straightforward.

### Built-in Support
CI/CD services like **GitHub Actions**, **CircleCI**, **GitLab CI**, and **Jenkins** have built-in support for securely handling environment variables. They allow secrets to be injected directly into the build or deployment process without being exposed in code or configuration files.


## Who This Project is Best For:

### Small to Medium Projects:

This approach works well for smaller-scale infrastructure projects or when working on personal or local environments.

### Local Development:

Developers working on local development or testing environments where using costly secrets management services isn't necessary.

### Cost-Conscious Projects:

If you're trying to avoid the cost associated with cloud secret management services for smaller projects, this project provides an effective alternative.

## Security Considerations

While Terraform-EnvHelper is a great solution for local development and cost-conscious projects, it’s important to note that `.env` files are not as secure as cloud-based secret management solutions. For production environments, you should consider encrypting your `.env` files or using a more robust solution like AWS Secrets Manager or HashiCorp Vault.



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

Also, create an env_vars.json file to list the variable names (in lowercase) that you want to pass to Terraform:

```json
["aws_access_key_id", "aws_secret_access_key", "db_password"]
```

### 3. Run the Script and Apply Terraform

Run the provided `read_env.sh` script to load environment variables from the `.env` file, and then initialize and apply your Terraform configuration:

```bash
bash read_env.sh
terraform init
terraform apply
```

**Terraform-EnvHelper** uses the `external` data source in Terraform along with a shell script (`read_env.sh`) to load environment variables from the `.env` file. These environment variables are then passed into Terraform for use in your configurations, allowing you to keep sensitive data secure and out of your codebase.

Here’s the `read_env.sh` script used to load the environment variables:

```bash
#!/bin/bash

# Default file names
ENV_FILE=${1:-.env}
ENV_VARS_FILE=${2:-env_vars.json}

# Load the environment variable names from the specified JSON file
ENV_VARS=$(jq -r '.[]' "$ENV_VARS_FILE")

# Function to check if .env file exists and load it
load_env_file() {
  if [ -f "$ENV_FILE" ]; then
    echo "$ENV_FILE file found. Loading environment variables from $ENV_FILE." >&2  # Print debug message to stderr
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
  else
    echo "$ENV_FILE file not found. Using system environment variables." >&2  # Print debug message to stderr
  fi
}

# Load .env if it exists, or use system environment variables
load_env_file

# Initialize an associative array to store variable values
declare -A env_values

# Loop through the list and check if the corresponding environment variables are set
for var_name in $ENV_VARS; do
  var_upper=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')

  # Fetch the value from either the .env file or system environment
  env_value="${!var_upper}"

  if [ -z "$env_value" ]; then
    echo "Error: $var_upper is not set. Exiting." >&2  # Print error message to stderr
    exit 1
  fi

  # Store the value in the associative array
  env_values[$var_name]="$env_value"
done

# Construct the jq arguments dynamically
jq_args=""
jq_object=""

for var_name in $ENV_VARS; do
  jq_args+=" --arg ${var_name} \"${env_values[$var_name]}\""
  if [[ -z "$jq_object" ]]; then
    jq_object="\"$var_name\": \$$var_name"
  else
    jq_object+=", \"$var_name\": \$$var_name"
  fi
done

# Print JSON output to stdout
eval "jq -n $jq_args '{$jq_object}'"


```

### Adding New Environment Variables

When adding new environment variables, you need to update both the .env file and the env_vars.json file:

Update the .env file with your new variable:

```bash
NEW_VARIABLE=new_value
```

Update the env_vars.json file to include the new variable:

```json
["aws_access_key_id", "aws_secret_access_key", "db_password", "new_variable"]
```

By keeping both the .env file and env_vars.json file in sync, you ensure that any newly added environment variables will be loaded and passed into Terraform.

### Example Use Case

Once the environment variables are loaded, you can use them in your Terraform configuration, for example:

```hcl
# Use external data source to load secrets from .env file
data "external" "env_vars" {
  program = ["./read_env.sh"]
  # Alternatively, specify custom .env and env_vars.json files
  # This allows flexibility to switch between different environments or configurations
  # Example:
  # program = ["./read_env.sh", "custom.env", "custom_env_vars.json"]
}

# Output the secrets (be careful, this will expose them in the output!)
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
- **Customizability**: Specify different .env and env_vars.json files to adapt to different environments.
- **Linux Compatibility**: Works seamlessly on **Linux/Ubuntu** environments.

## Contribution

We welcome contributions to Terraform-EnvHelper! If you'd like to contribute, here’s how you can get involved:

### Reporting Issues
If you encounter any bugs or have suggestions for improvements, feel free to open an issue in the GitHub repository. Please include a clear description of the issue and, if possible, steps to reproduce it.

### Submitting Changes
If you'd like to submit code changes, you can fork the repository, make your changes, and submit a pull request. Please ensure that your pull request includes:
- A clear description of the changes.
- Adherence to the project’s existing style and structure.
- Any necessary updates to documentation.

### Feedback and Ideas
We’re always open to feedback and ideas for improving the project. If you have suggestions or would like to discuss new features, open an issue or start a discussion in the GitHub repository.

Thank you for your interest in contributing to Terraform-EnvHelper!

## License

Terraform-EnvHelper is licensed under the MIT License.
