#!/usr/bin/env bash
# A collection of useful assertions. Each one checks a condition and if the condition is not satisfied, exits the
# program. This is useful for defensive programming.

# shellcheck source=./modules/bash-commons/src/log.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log.sh"
# shellcheck source=./modules/bash-commons/src/array.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/array.sh"
# shellcheck source=./modules/bash-commons/src/string.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/string.sh"
# shellcheck source=./modules/bash-commons/src/os.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/os.sh"

# Check that the given binary is available on the PATH. If it's not, exit with an error.
function assert_is_installed {
  local -r name="$1"

  if ! os_command_is_installed "$name"; then
    log_error "The command '$name' is required by this script but is not installed or in the system's PATH."
    exit 1
  fi
}

# Check that the value of the given arg is not empty. If it is, exit with an error.
function assert_not_empty {
  local -r arg_name="$1"
  local -r arg_value="$2"
  local -r reason="$3"

  if [[ -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' cannot be empty. $reason"
    exit 1
  fi
}

# Check that the value of the given arg is empty. If it isn't, exit with an error.
function assert_empty {
  local -r arg_name="$1"
  local -r arg_value="$2"
  local -r reason="$3"

  if [[ ! -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' must be empty. $reason"
    exit 1
  fi
}

# Check that the given response from AWS is not empty or null (the null often comes from trying to parse AWS responses
# with jq). If it is, exit with an error.
function assert_not_empty_or_null {
  local -r response="$1"
  local -r description="$2"

  if string_is_empty_or_null "$response"; then
    log_error "Got empty response for $description"
    exit 1
  fi
}

# Check that the given value is one of the values from the given list. If not, exit with an error.
function assert_value_in_list {
  local -r arg_name="$1"
  local -r arg_value="$2"
  shift 2
  local -ar list=("$@")

  if ! array_contains "$arg_value" "${list[@]}"; then
    log_error "'$arg_value' is not a valid value for $arg_name. Must be one of: [${list[@]}]."
    exit 1
  fi
}

# Reads in a list of keys and values and asserts that one and only one of the values is set.
# This is useful for command line options that are mutually exclusive.
# Example:
#   assert_exactly_one_of "--opt1" "" "--opt2" "val2" "--opt3" "" "--opt4" ""
# Examples that assert failure:
#   assert_exactly_one_of "--opt1" "val1" "--opt2" "val2" "--opt3" "" "--opt4" ""
#   assert_exactly_one_of "--opt1" "" "--opt2" "" "--opt3" "" "--opt4" ""
function assert_exactly_one_of {
  local -ra args=("$@")
  local -r num_args="${#args[@]}"
  if [[ "$((num_args % 2))" -ne 0 ]]; then
    log_error "This script expects an even number of arguments but received $num_args instead."
    exit 1
  fi

  local num_non_empty=0
  local -a arg_names=()

  # Determine how many arg_vals are non-empty
  for (( i=0; i<$((num_args)); i+=2 )); do
    arg_names+=("${args[i]}")
    if [[ ! -z "${args[i+1]}" ]]; then
      num_non_empty=$((num_non_empty+1))
    fi
  done

  if [[ "$num_non_empty" -ne 1 ]]; then
    log_error "Exactly one of ${arg_names[*]} must be set."
    exit 1
  fi
}

# Check that this script is running as root or sudo and exit with an error if it's not
function assert_uid_is_root_or_sudo {
  if ! os_user_is_root_or_sudo; then
    log_error "This script should be run using sudo or as the root user"
    exit 1
  fi
}