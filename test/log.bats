#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/../modules/bash-commons/src/log.sh"
load "test-helper"

@test "log_info string" {
  run log_info "Hello, World"
  assert_success
  assert_output_regex "^.*INFO.*Hello, World$"
}

@test "log_warn string" {
  run log_warn "Hello, World"
  assert_success
  assert_output_regex "^.*WARN.*Hello, World$"
}

@test "log_error string" {
  run log_error "Hello, World"
  assert_success
  assert_output_regex "^.*ERROR.*Hello, World$"
}
