#!/usr/bin/env bash

# Returns 0 if the given item (needle) is in the given array (haystack); returns 1 otherwise.
function array_contains {
  local -r needle="$1"
  shift
  local -ra haystack=("$@")

  local item
  for item in "${haystack[@]}"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}

# Splits the given $string into an array of elements based on the given $separator
#
# Examples:
#
# array_split "," "a,b,c"
#   Returns: ("a" "b" "c")
#
# Hint:
# When calling this function, use the following construction: ary=( $(array_split "," "a,b,c") )
#
# Sources:
# - https://stackoverflow.com/a/15988793/2308858
function array_split {
  local -r separator="$1"
  local -r str="$2"
  local -a ary=()

  IFS="$separator" read -a ary <<<"$str"

  echo ${ary[*]}
}

# Joins the elements of the given array into a string with the given separator between each element.
#
# Examples:
#
# array_join "," ("A" "B" "C")
#   Returns: "A,B,C"
#
function array_join {
  local -r separator="$1"
  shift
  local -ar values=("$@")

  local out=""
  for (( i=0; i<"${#values[@]}"; i++ )); do
    if [[ "$i" -gt 0 ]]; then
      out="${out}${separator}"
    fi
    out="${out}${values[i]}"
  done

  echo -n "$out"
}

# Adds the given $prefix to the beginning of each string element in the given $array
#
# Examples:
#
# array_prepend "P" "a" "b" "c"
#   Returns: ("Pa" "Pb" "Pc")
#
# Hint:
# When calling this function, use the following construction: ary=( $(array_prepend "P" "a" "b" "c") )
#
# Sources:
# - https://stackoverflow.com/a/13216833/2308858
#
function array_prepend {
  local -r prefix="$1"
  shift 1
  local -ar ary=($@)

  updated_ary=( "${ary[@]/#/$prefix}" )
  echo ${updated_ary[*]}
}