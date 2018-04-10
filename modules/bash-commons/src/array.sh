#!/bin/bash

set -e

# Returns 0 if the given item (needle) is in the given array (haystack); returns 1 otherwise.
function array_contains {
  local readonly needle="$1"
  shift
  local readonly haystack=("$@")

  local item
  for item in "${haystack[@]}"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}

# Joins the elements of the given array into a string with the given separator between each element.
#
# Examples:
#
# array_join "," ("A" "B" "C")
#   Returns: "A,B,C"
#
function array_join {
  local readonly separator="$1"
  shift
  local readonly values=("$@")

  local out=""
  for (( i=0; i<"${#values[@]}"; i++ )); do
    if [[ "$i" -gt 0 ]]; then
      out="${out}${separator}"
    fi
    out="${out}${values[i]}"
  done

  echo -n "$out"
}
