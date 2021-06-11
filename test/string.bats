#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/../modules/bash-commons/src/string.sh"
load "test-helper"

@test "string_contains haystack empty needle empty, match" {
  run string_contains "" ""
  assert_success
}

@test "string_contains haystack empty needle has value, no match" {
  run string_contains "" "foo"
  assert_failure
}

@test "string_contains haystack has value, needle empty, match" {
  run string_contains "foo" ""
  assert_success
}

@test "string_contains haystack has value, needle has value, no match" {
  run string_contains "foo" "bar"
  assert_failure
}

@test "string_contains haystack has value, needle has value, exact match" {
  run string_contains "foo" "foo"
  assert_success
}

@test "string_contains haystack has value, needle has value, internal match" {
  run string_contains "foo bar baz" "bar"
  assert_success
}

@test "string_multiline_contains haystack empty needle empty, match" {
  run string_multiline_contains "" ""
  assert_success
}

@test "string_multiline_contains haystack empty needle has value, no match" {
  run string_multiline_contains "" "foo"
  assert_failure
}

@test "string_multiline_contains haystack has value, needle empty, match" {
  run string_multiline_contains "foo" ""
  assert_success
}

@test "string_multiline_contains haystack has value, needle has value, no match" {
  run string_multiline_contains "foo" "bar"
  assert_failure
}

@test "string_multiline_contains haystack has value, needle has value, exact match" {
  run string_multiline_contains "foo" "foo"
  assert_success
}

@test "string_multiline_contains haystack has value, needle has value, internal match" {
  run string_multiline_contains "foo bar baz" "bar"
  assert_success
}

@test "string_multiline_contains haystack has multiline value, needle has value, internal match" {
  local readonly multiline=$(echo -e "foo\nbar\nbaz")
  run string_multiline_contains "$multiline" "bar"
  assert_success
}

@test "string_multiline_contains haystack has multiline value, needle has value, no match" {
  local readonly multiline=$(echo -e "foo\na bar b\nbaz")
  run string_multiline_contains "$multiline" "bar"
  assert_success
}

@test "string_multiline_contains haystack has multiline value, needle has value, regex match" {
  local readonly multiline=$(echo -e "foo\na bar b\nbaz")
  run string_multiline_contains "$multiline" ".*bar.*"
  assert_success
}

@test "string_to_uppercase input lowercase" {
  run string_to_uppercase "foo"
  assert_success
  assert_output "FOO"
}

@test "string_to_uppercase input uppercase" {
  run string_to_uppercase "FOO"
  assert_success
  assert_output "FOO"
}

@test "string_to_uppercase input mixed" {
  run string_to_uppercase "fOo"
  assert_success
  assert_output "FOO"
}

@test "string_strip_prefix empty string, empty prefix" {
  run string_strip_prefix "" ""
  assert_success
  assert_output ""
}

@test "string_strip_prefix empty string, non empty prefix" {
  run string_strip_prefix "" "foo"
  assert_success
  assert_output ""
}

@test "string_strip_prefix non empty string, empty prefix" {
  run string_strip_prefix "foo" ""
  assert_success
  assert_output "foo"
}

@test "string_strip_prefix non empty string, non empty prefix, no match" {
  run string_strip_prefix "foo" "bar"
  assert_success
  assert_output "foo"
}

@test "string_strip_prefix non empty string, non empty prefix, exact match" {
  run string_strip_prefix "foo=bar" "foo="
  assert_success
  assert_output "bar"
}

@test "string_strip_prefix non empty string, non empty prefix, wildcard match" {
  run string_strip_prefix "foo=bar" "*="
  assert_success
  assert_output "bar"
}

@test "string_strip_suffix empty string, empty suffix" {
  run string_strip_suffix "" ""
  assert_success
  assert_output ""
}

@test "string_strip_suffix empty string, non empty suffix" {
  run string_strip_suffix "" "foo"
  assert_success
  assert_output ""
}

@test "string_strip_suffix non empty string, empty suffix" {
  run string_strip_suffix "foo" ""
  assert_success
  assert_output "foo"
}

@test "string_strip_suffix non empty string, non empty suffix, no match" {
  run string_strip_suffix "foo" "bar"
  assert_success
  assert_output "foo"
}

@test "string_strip_suffix non empty string, non empty suffix, exact match" {
  run string_strip_suffix "foo=bar" "=bar"
  assert_success
  assert_output "foo"
}

@test "string_strip_suffix non empty string, non empty suffix, wildcard match" {
  run string_strip_suffix "foo=bar" "=*"
  assert_success
  assert_output "foo"
}

@test "string_is_empty_or_null empty string" {
  run string_is_empty_or_null ""
  assert_success
}

@test "string_is_empty_or_null null string" {
  run string_is_empty_or_null "null"
  assert_success
}

@test "string_is_empty_or_null non empty string" {
  run string_is_empty_or_null "foo"
  assert_failure
}

@test "string_substr empty string" {
    run string_substr "" 0 0
    assert_success
}

@test "string_substr non empty string" {
    run string_substr "hello world" 0 5
    assert_success
    assert_output "hello"
}
