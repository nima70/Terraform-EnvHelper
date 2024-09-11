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
