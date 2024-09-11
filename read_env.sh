#!/bin/bash

# Default file names with validation
ENV_FILE=""
ENV_VARS_FILE=""
VERBOSE_MODE=false

# Parse arguments for file names and --verbose flag
while [[ "$1" ]]; do
  case $1 in
    --verbose)
      VERBOSE_MODE=true
      ;;
    *.env)
      ENV_FILE="$1"
      ;;
    *.json)
      ENV_VARS_FILE="$1"
      ;;
    *)
      echo "Error: Unsupported file type for '$1'. Only .env and .json files are allowed." >&2
      exit 1
      ;;
  esac
  shift
done

# Default file names if not provided
ENV_FILE=${ENV_FILE:-.env}
ENV_VARS_FILE=${ENV_VARS_FILE:-env_vars.json}

# Function for logging messages
log() {
  local message=$1
  if [ "$VERBOSE_MODE" = true ]; then
    echo "$message" >&2
  fi
}

# Function to validate file names and ensure safe patterns
validate_file_name() {
  local file_name=$1
  local allowed_pattern='^[a-zA-Z0-9._-]+$'

  if [[ ! $file_name =~ $allowed_pattern ]]; then
    echo "Error: Invalid file name '$file_name'. Only alphanumeric characters, dashes, underscores, and periods are allowed." >&2
    exit 1
  fi

  # Check if the file has the correct extension (.env or .json)
  if [[ $file_name != *.env && $file_name != *.json ]]; then
    echo "Error: Unsupported file type for '$file_name'. Only .env and .json files are allowed." >&2
    exit 1
  fi
}

# Validate the environment variable file names for safety
validate_file_name "$ENV_FILE"
validate_file_name "$ENV_VARS_FILE"

# Function to validate the structure of the JSON file
validate_json_file() {
  local json_file=$1

  # Check if the file contains valid JSON and is an array of strings
  if ! jq -e '. | type == "array" and (length > 0) and (.[0] | type == "string")' "$json_file" > /dev/null 2>&1; then
    echo "Error: Invalid JSON structure in $json_file. It must be a non-empty array of strings." >&2
    exit 1
  fi
}

# Validate the structure of the env_vars.json file
validate_json_file "$ENV_VARS_FILE"

# Function to manually load .env variables without exporting them to subshells
load_env_file() {
  if [ -f "$ENV_FILE" ]; then
    log "$ENV_FILE file found. Loading environment variables from $ENV_FILE."
    
    # Manually read .env variables without using set -o allexport
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
      if [[ ! "$key" =~ ^# && "$key" != "" ]]; then
        key=$(echo "$key" | xargs)    # Trim spaces
        value=$(echo "$value" | xargs)  # Trim spaces

        # Validate variable values
        if [ -z "$value" ]; then
          echo "Error: Value for $key cannot be empty." >&2
          exit 1
        fi

        log "Setting environment variable: $key"  # Log only in verbose mode
        export "$key=$value"  # Manually export each key-value pair
      fi
    done < "$ENV_FILE"
    
  else
    echo "$ENV_FILE file not found. Using system environment variables." >&2
  fi
}

# Load .env if it exists, or use system environment variables
load_env_file

# Initialize an associative array to store variable values
declare -A env_values

# Loop through the list and check if the corresponding environment variables are set
for var_name in $(jq -r '.[]' "$ENV_VARS_FILE"); do
  var_upper=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')

  # Fetch the value from either the .env file or system environment
  env_value="${!var_upper}"

  if [ -z "$env_value" ]; then
    # Secure error logging: Do not log sensitive information
    echo "Error: $var_upper is not set. Exiting." >&2
    exit 1
  fi

  log "$var_upper is set and will be included in the output."  # Verbose logging
  # Store the value in the associative array
  env_values[$var_name]="$env_value"
done

# Construct the jq arguments dynamically
jq_args=""
jq_object=""

for var_name in $(jq -r '.[]' "$ENV_VARS_FILE"); do
  jq_args+=" --arg ${var_name} \"${env_values[$var_name]}\""
  if [[ -z "$jq_object" ]]; then
    jq_object="\"$var_name\": \$$var_name"
  else
    jq_object+=", \"$var_name\": \$$var_name"
  fi
done

log "Generating JSON output using jq."  # Verbose logging

# Print JSON output to stdout
eval "jq -n $jq_args '{$jq_object}'"
