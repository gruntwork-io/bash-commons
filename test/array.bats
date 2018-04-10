#!/usr/bin/env bats
#
# Unit tests for docker-osx-dev. To run these tests, you must have bats
# installed. See https://github.com/sstephenson/bats

source "$BATS_TEST_DIRNAME/../modules/bash-commons/src/array.sh"
load "test-helper"

@test "array_contains on empty array" {
  run array_contains "foo"
  assert_failure
}

@test "array_contains on array of length 1 for non matching item" {
  run array_contains "foo" "bar"
  assert_failure
}

@test "array_contains on array of length 1 for matching item" {
  run array_contains "foo" "foo"
  assert_success
}

@test "array_contains on array of length 3 for non matching item" {
  run array_contains "foo" "bar" "baz" "blah"
  assert_failure
}

@test "array_contains on array of length 3 for matching item" {
  run array_contains "foo" "bar" "foo" "blah"
  assert_success
}

@test "array_contains on array of length 3 for multiple matches" {
  run array_contains "foo" "bar" "foo" "foo"
  assert_success
}