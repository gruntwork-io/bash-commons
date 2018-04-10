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

@test "assert_uid_is_root_or_sudo as root" {
  run assert_uid_is_root_or_sudo
  assert_success
}

@test "assert_uid_is_root_or_sudo as non-root" {
  local readonly unique_id=$(unique_id 8)
  local readony test_user="user-for-test-$unique_id"

  useradd "$test_user"
  run su "$test_user" -c "source $BATS_TEST_DIRNAME/../modules/bash-commons/src/assert.sh && assert_uid_is_root_or_sudo"
  userdel "$test_user"

  assert_failure
  assert_output_regex ".*This script should be run using sudo or as the root user"
}
