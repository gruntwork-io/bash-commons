#!/bin/bash
# A collection of useful assertions. Each one checks a condition and if the condition is not satisfied, exits the
# program. This is useful for defensive programming.


set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/array.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/string.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/os.sh"

# Check that the given binary is available on the PATH. If it's not, exit with an error.
function assert_is_installed {
  local readonly name="$1"

  if ! os_command_is_installed "$name"; then
    log_error "The command '$name' is required by this script but is not installed or in the system's PATH."
    exit 1
  fi
}

# Check that the value of the given arg is not empty. If it is, exit with an error.
function assert_not_empty {
  local readonly arg_name="$1"
  local readonly arg_value="$2"
  local readonly reason="$3"

  if [[ -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' cannot be empty. $reason"
    exit 1
  fi
}

# Check that the value of the given arg is empty. If it isn't, exit with an error.
function assert_empty {
  local readonly arg_name="$1"
  local readonly arg_value="$2"
  local readonly reason="$3"

  if [[ ! -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' must be empty. $reason"
    exit 1
  fi
}

# Check that the given response from AWS is not empty or null (the null often comes from trying to parse AWS responses
# with jq). If it is, exit with an error.
function assert_not_empty_or_null {
  local readonly response="$1"
  local readonly description="$2"

  if string_is_empty_or_null "$response"; then
    log_error "Got empty response for $description"
    exit 1
  fi
}

# Check that the given value is one of the values from the given list. If not, exit with an error.
function assert_value_in_list {
  local readonly arg_name="$1"
  local readonly arg_value="$2"
  shift 2
  local readonly list=($@)

  if ! array_contains "$arg_value" "${list[@]}"; then
    log_error "'$arg_value' is not a valid value for $arg_name. Must be one of: [${list[@]}]."
    exit 1
  fi
}

# Check that this script is running as root or sudo and exit with an error if it's not
function assert_uid_is_root_or_sudo {
  if [[ $EUID != 0 ]]; then
    log_error "This script should be run using sudo or as the root user"
    exit 1
  fi
}