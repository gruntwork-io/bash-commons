#!/bin/bash
# This is a series of helper functions copy/pasted from many other repos that use BATS for testing. The code isn't
# pretty, and doesn't follow many of our conventions, but it's useful.

flunk() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "$@"
    fi
  } >&2
  return 1
}

# Adapted from https://unix.stackexchange.com/a/230676/215969
unique_id() {
  local -r length="$1"
  head /dev/urandom | tr -dc A-Za-z0-9 | head -c "$length" ; echo ''
}

assert_success() {
  if [ "$status" -ne 0 ]; then
    flunk "command failed with exit status $status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    flunk "expected failed exit status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_equal() {
  if [ "$1" != "$2" ]; then
    { echo "expected: $1"
      echo "actual:   $2"
    } | flunk
  fi
}

assert_equal_regex() {
  if [[ ! "$2" =~ $1 ]]; then
    { echo "expected: $1"
      echo "actual:   $2"
    } | flunk
  fi
}

assert_equal_json() {
  local -r expected="$1"
  local -r actual="$2"

  # To avoid false negatives resulting from unordered keys, we do the equality check in python.
  local -r checker_py=$(cat <<END_HEREDOC
import json
expected_raw = '''
$expected
'''
expected_json = json.loads(expected_raw)
actual_raw = '''
$actual
'''
actual_json = json.loads(actual_raw)
print(expected_json == actual_json)
END_HEREDOC
)

  local result
  result="$(python3 -c "$checker_py")"

  if [[ "$result" != 'True' ]]; then
    { echo "expected: $expected"
      echo "actual:   $actual"
    } | flunk
  fi
}

assert_greater_than() {
  if [ ! "$1" -gt "$2" ]; then
    echo "expected $1 to be greater than $2" | flunk
  fi
}

assert_output() {
  local expected
  if [ $# -eq 0 ]; then expected="$(cat -)"
  else expected="$1"
  fi
  assert_equal "$expected" "$output"
}

assert_output_regex() {
  local expected
  if [ $# -eq 0 ]; then expected="$(cat -)"
  else expected="$1"
  fi
  assert_equal_regex "$expected" "$output"
}

assert_output_json() {
  local expected
  if [ $# -eq 0 ]; then expected="$(cat -)"
  else expected="$1"
  fi
  assert_equal_json "$expected" "$output"
}

assert_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    assert_equal "$2" "${lines[$1]}"
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then return 0; fi
    done
    flunk "expected line \`$1'"
  fi
}

refute_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    local num_lines="${#lines[@]}"
    if [ "$1" -lt "$num_lines" ]; then
      flunk "output has $num_lines lines"
    fi
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then
        flunk "expected to not find line \`$line'"
      fi
    done
  fi
}

assert() {
  if ! "$@"; then
    flunk "failed: $@"
  fi
}

stub() {
  [ -d "$BATS_TEST_DIRNAME/stub" ] || mkdir "$BATS_TEST_DIRNAME/stub"
  #touch "$BATS_TEST_DIRNAME/stub/$1"
  echo "$2" > "$BATS_TEST_DIRNAME/stub/$1"
  chmod +x "$BATS_TEST_DIRNAME/stub/$1"
}

rm_stubs() {
  rm -rf "$BATS_TEST_DIRNAME/stub"
}
