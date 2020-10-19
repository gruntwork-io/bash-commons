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

# Applies a functional reduce to an array of arguments. Supports mathmatical expressions only (see man expr)
# The first argument should be a single quoted string representing a statment to evaluate values with. It 
# expects the following variables, expanded as:
#   $1 - the reducer, starting at the first value in the array, the resulting value of the entire expression 
#        becomes this value on the next call
#   $2 - the next item in the array
#
# Synopsis:
#
# array_reduce <expression> <elements>...
#
# Examples:
# 
# array_reduce '$1 * $2' 1 2 3 4 5
#   Returns: 120
#
# Hint: In the expression string, $1 is initialized to the first element in the array, and $2 starts as the second element.
function array_reduce {
    local -r expression="$1"
    local reducer="$2"
    shift
    local -ar ary=("$@")

    for (( i=0; i<"${#ary[@]}"; i++ )); do
        # Expand the expression to be evaluated, by replacing $1 and $2 with the reducer and next array element, respectively
        # Additionally, make modify '*' to the multiplication token used by expr ('\*') for convience.
        local expression_expanded="$(printf "$expression" | sed "s/\$1/$reducer/g; s/\$2/${ary[i]}/g" )"

        # update the reducer with the result of the next element evaluated by the expression.
        reducer=$(eval "expr $expression_expanded")
        if [[  "$?" -ne 0 ]]; then
            >&2 echo "failed on expression $expression_expanded"
            return 1
        fi
    done

    echo "$reducer"
}
