#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/../modules/bash-commons/src/assert.sh"
load "test-helper"

@test "assert_is_installed on bash built in" {
  run assert_is_installed "echo"
  assert_success
}

@test "assert_is_installed on installed app" {
  run assert_is_installed "bats"
  assert_success
}

@test "assert_is_installed on non-existent app" {
  run assert_is_installed "not-a-real-app"
  assert_failure
}

@test "assert_not_empty on empty string" {
  run assert_not_empty "--foo"
  assert_failure
}

@test "assert_not_empty on non-empty string" {
  run assert_not_empty "--foo" "bar"
  assert_success
}

@test "assert_not_empty on null string" {
  run assert_not_empty "--foo" "null"
  assert_success
}

@test "assert_not_empty on empty array" {
  local empty=()
  run assert_not_empty "--foo" "${empty[@]}"
  assert_failure
}

@test "assert_not_empty on non-empty array" {
  local non_empty=("foo" "bar" "baz")
  run assert_not_empty "--foo" "${non_empty[@]}"
  assert_success
}

@test "assert_empty on empty string" {
  run assert_empty "--foo"
  assert_success
}

@test "assert_empty on non-empty string" {
  run assert_empty "--foo" "bar"
  assert_failure
}

@test "assert_empty on empty array" {
  local empty=()
  run assert_empty "--foo" "${empty[@]}"
  assert_success
}

@test "assert_empty on non-empty array" {
  local non_empty=("foo" "bar" "baz")
  run assert_empty "--foo" "${non_empty[@]}"
  assert_failure
}

@test "assert_not_empty_or_null on empty string" {
  run assert_not_empty_or_null
  assert_failure
}

@test "assert_not_empty_or_null on non-empty string" {
  run assert_not_empty_or_null "bar"
  assert_success
}

@test "assert_not_empty_or_null on null string" {
  run assert_not_empty_or_null "null"
  assert_failure
}

@test "assert_not_empty_or_null on empty array" {
  local readonly empty=()
  run assert_not_empty_or_null "${empty[@]}"
  assert_failure
}

@test "assert_not_empty_or_null on non-empty array" {
  local readonly non_empty=("foo" "bar" "baz")
  run assert_not_empty_or_null "${non_empty[@]}"
  assert_success
}

@test "assert_value_in_list empty list" {
  run assert_value_in_list "--foo" "foo"
  assert_failure
}

@test "assert_value_in_list list of length 1, no match" {
  run assert_value_in_list "--foo" "foo" "bar"
  assert_failure
}

@test "assert_value_in_list list of length 3, no match" {
  run assert_value_in_list "--foo" "foo" "bar" "baz" "blah"
  assert_failure
}

@test "assert_value_in_list list of length 1, match" {
  run assert_value_in_list "--foo" "foo" "foo"
  assert_success
}

@test "assert_value_in_list list of length 3, match" {
  run assert_value_in_list "--foo" "foo" "bar" "baz" "foo"
  assert_success
}

@test "assert_value_in_list list of length 3, with spaces in the values, no match" {
  run assert_value_in_list "--foo" "foo" "foo bar" "baz blah"
  assert_failure
}

@test "assert_exactly_one_of list of length 2, with value in pos 1" {
  run assert_exactly_one_of "--foo" "foo" "--bar" ""
  assert_success
}

@test "assert_exactly_one_of list of length 2, with value in pos 2" {
  run assert_exactly_one_of "--foo" "" "--bar" "bar"
  assert_success
}

@test "assert_exactly_one_of list of length 3, with value in pos 1" {
  run assert_exactly_one_of "--foo" "foo" "--bar" "" "--baz" ""
  assert_success
}

@test "assert_exactly_one_of list of length 3, with value in pos 2" {
  run assert_exactly_one_of "--foo" "" "--bar" "bar" "--baz" ""
  assert_success
}

@test "assert_exactly_one_of list of length 3, with value in pos 3" {
  run assert_exactly_one_of "--foo" "" "--bar" "" "--baz" "baz"
  assert_success
}

@test "assert_exactly_one_of list of length 3, with value in pos 1 and 2" {
  run assert_exactly_one_of "--foo" "foo" "--bar" "bar" "--baz" ""
  assert_failure
}

@test "assert_exactly_one_of list of length 3, with value in pos 1 and 3" {
  run assert_exactly_one_of "--foo" "foo" "--bar" "" "--baz" "baz"
  assert_failure
}

@test "assert_exactly_one_of list of length 3, with value in pos 2 and 3" {
  run assert_exactly_one_of "--foo" "" "--bar" "bar" "--baz" "baz"
  assert_failure
}

@test "assert_exactly_one_of list of length 3, with value in pos 1, 2 and 3" {
  run assert_exactly_one_of "--foo" "foo" "--bar" "bar" "--baz" "baz"
  assert_failure
}

@test "assert_exactly_one_of list of length 4, with value in pos 2" {
  run assert_exactly_one_of "--foo" "" "--bar" "bar" "--baz" "" "--qux" ""
  assert_success
}

@test "assert_exactly_one_of list of length 4, with value in pos 2 and 4" {
  run assert_exactly_one_of "--foo" "" "--bar" "bar" "--baz" "" "--qux" "qux"
  assert_failure
}

@test "assert_exactly_one_of list of length 4, with no value set" {
  run assert_exactly_one_of "--foo" "" "--bar" "" "--baz" "" "--qux" ""
  assert_failure
}

@test "assert_exactly_one_of list of length 5, with one value set, fails for odd num_args" {
  run assert_exactly_one_of "--foo" "foo" "--bar" "" "--baz" "" "--qux"
  assert_failure
}

@test "assert_uid_is_root_or_sudo as root" {
  run assert_uid_is_root_or_sudo
  assert_success
}
