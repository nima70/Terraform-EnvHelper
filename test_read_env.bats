#!/usr/bin/env bats

# Helper function to run the script and capture JSON output
run_and_extract_json() {
  local env_file="$1"
  local env_vars_file="$2"
  run bash read_env.sh "$env_file" "$env_vars_file"

  # Filter to extract only the JSON output between { and }
  json_output=$(echo "$output" | awk '/^{/{flag=1} flag; /}/{flag=0}')
  
  # Ensure the script succeeded
  [ "$status" -eq 0 ]

  # Return the extracted JSON output
  echo "$json_output"
}

# Helper function to validate the expected environment variables in the JSON output
validate_env_vars() {
  local expected_aws_access_key_id="$1"
  local expected_aws_secret_access_key="$2"
  local expected_db_password="$3"

  # Assert that the expected values match the JSON output
  [ "$(jq -r '.aws_access_key_id' <<< "$json_output")" = "$expected_aws_access_key_id" ]
  [ "$(jq -r '.aws_secret_access_key' <<< "$json_output")" = "$expected_aws_secret_access_key" ]
  [ "$(jq -r '.db_password' <<< "$json_output")" = "$expected_db_password" ]
}

setup() {
  # Create a temporary .env file and set environment variables
  touch test.env
  echo 'AWS_ACCESS_KEY_ID=test_key_id' > test.env
  echo 'AWS_SECRET_ACCESS_KEY=test_secret_key' >> test.env
  echo 'DB_PASSWORD=test_db_password' >> test.env

  # Create the corresponding env_vars.json file
  echo '["aws_access_key_id", "aws_secret_access_key", "db_password"]' > test_env_vars.json
}

# Test loading variables from a specific .env and env_vars.json file
@test "Load variables from specified .env and env_vars.json" {
  json_output=$(run_and_extract_json "test.env" "test_env_vars.json")

  # Validate environment variables in the extracted JSON
  validate_env_vars "test_key_id" "test_secret_key" "test_db_password"
}

# Test fallback to system environment variables when .env file does not exist
@test "Fallback to system environment variables when .env file does not exist" {
  # Remove the test.env file for this test
  rm -f test.env

  # Set environment variables in the system
  export AWS_ACCESS_KEY_ID="system_key_id"
  export AWS_SECRET_ACCESS_KEY="system_secret_key"
  export DB_PASSWORD="system_db_password"

  json_output=$(run_and_extract_json "test.env" "test_env_vars.json")

  # Validate environment variables in the extracted JSON
  validate_env_vars "system_key_id" "system_secret_key" "system_db_password"
}


# Test dynamic construction of jq command
@test "Check if jq command is dynamically constructed" {
  # Create a basic .env file with test values
  echo 'AWS_ACCESS_KEY_ID="dynamic_test_key_id"' > test.env
  echo 'AWS_SECRET_ACCESS_KEY="dynamic_test_secret_key"' >> test.env
  echo 'DB_PASSWORD="dynamic_test_db_password"' >> test.env

  json_output=$(run_and_extract_json "test.env" "test_env_vars.json")

  # Validate environment variables in the extracted JSON
  validate_env_vars "dynamic_test_key_id" "dynamic_test_secret_key" "dynamic_test_db_password"
}
