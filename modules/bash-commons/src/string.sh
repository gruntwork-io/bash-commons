#!/usr/bin/env bash

# Return true (0) if the first string (haystack) contains the second string (needle), and false (1) otherwise.
function string_contains {
  local -r haystack="$1"
  local -r needle="$2"

  [[ "$haystack" == *"$needle"* ]]
}

# Returns true (0) if the first string (haystack), which is assumed to contain multiple lines, contains the second
# string (needle), and false (1) otherwise. The needle can contain regular expressions.
function string_multiline_contains {
  local -r haystack="$1"
  local -r needle="$2"

  echo "$haystack" | grep -q "$needle"
}

# Convert the given string to uppercase
function string_to_uppercase {
  local -r str="$1"
  echo "$str" | awk '{print toupper($0)}'
}

# Strip the prefix from the given string. Supports wildcards.
#
# Example:
#
# string_strip_prefix "foo=bar" "foo="  ===> "bar"
# string_strip_prefix "foo=bar" "*="    ===> "bar"
#
# http://stackoverflow.com/a/16623897/483528
function string_strip_prefix {
  local -r str="$1"
  local -r prefix="$2"
  echo "${str#$prefix}"
}

# Strip the suffix from the given string. Supports wildcards.
#
# Example:
#
# string_strip_suffix "foo=bar" "=bar"  ===> "foo"
# string_strip_suffix "foo=bar" "=*"    ===> "foo"
#
# http://stackoverflow.com/a/16623897/483528
function string_strip_suffix {
  local -r str="$1"
  local -r suffix="$2"
  echo "${str%$suffix}"
}

# Return true if the given response is empty or "null" (the latter is from jq parsing).
function string_is_empty_or_null {
  local -r response="$1"
  [[ -z "$response" || "$response" == "null" ]]
}


# Given a string $str, return the substring beginning at index $start and ending at index $end.
#
# Example:
#
# string_substr "hello world" 0 5
#   Returns "hello"
function string_substr {
  local -r str="$1"
  local -r start="$2"
  local end="$3"

  if [[ "$start" -lt 0 || "$end" -lt 0 ]]; then
    log_error "In the string_substr bash function, each of \$start and \$end must be >= 0."
    exit 1
  fi

  if [[ "$start" -gt "$end" ]]; then
    log_error "In the string_substr bash function, \$start must be < \$end."
    exit 1
  fi

  if [[ -z "$end" ]]; then
    end="${#str}"
  fi

  echo "${str:$start:$end}"
}
