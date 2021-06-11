#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/../modules/bash-commons/src/os.sh"
load "test-helper"

@test "os_get_available_memory_mb" {
  run os_get_available_memory_mb
  assert_success
  assert_output_regex "[0-9]+"
}

@test "os_is_amazon_linux" {
  run os_is_amazon_linux
  assert_failure
}

@test "os_is_ubuntu" {
  run os_is_ubuntu
  assert_success
}

@test "os_is_darwin" {
  run os_is_darwin
  assert_failure
}

@test "os_validate_checksum valid sha256" {
  run os_validate_checksum "$BATS_TEST_DIRNAME/fixtures/checksum/foo.txt" "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae" "sha256"
  assert_success
}

@test "os_validate_checksum invalid sha256" {
  run os_validate_checksum "$BATS_TEST_DIRNAME/fixtures/checksum/foo.txt" "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7af" "sha256"
  assert_failure
}

@test "os_validate_checksum valid md5" {
  run os_validate_checksum "$BATS_TEST_DIRNAME/fixtures/checksum/foo.txt" "acbd18db4cc2f85cedef654fccc4a4d8" "md5"
  assert_success
}

@test "os_validate_checksum invalid md5" {
  run os_validate_checksum "$BATS_TEST_DIRNAME/fixtures/checksum/foo.txt" "bcbd18db4cc2f85cedef654fccc4a4d8" "md5"
  assert_failure
}

@test "os_command_is_installed bash built in" {
  run os_command_is_installed "echo"
  assert_success
}

@test "os_command_is_installed installed app" {
  run os_command_is_installed "bats"
  assert_success
}

@test "os_command_is_installed non-existent app" {
  run os_command_is_installed "not-a-real-app"
  assert_failure
}

@test "os_get_current_users_name" {
  run os_get_current_users_name
  assert_success
  assert_output "root"
}

@test "os_get_current_users_group" {
  run os_get_current_users_group
  assert_success
  assert_output "root"
}

@test "os_user_is_root_or_sudo for root user" {
  run os_user_is_root_or_sudo
  assert_success
}

@test "os_user_exists for root user" {
  run os_user_exists root
  assert_success
}

@test "os_user_exists for missing user" {
  run os_user_exists missing
  assert_failure
}

@test "os_create_user for new_user user" {
  local suffix
  suffix=$(date +%s)
  local -r username="new_user$suffix"
  run os_user_exists "$username"
  assert_failure
  run os_create_user "$username"
  assert_success
  run os_user_exists "$username"
  assert_success
}

@test "os_create_user with sudo for new_user_sudo user" {
  local suffix
  suffix=$(date +%s)
  local -r username="new_user_sudo$suffix"
  run os_user_exists "$username"
  assert_failure
  run os_create_user "$username" 'true'
  assert_success
  run os_user_exists "$username"
  assert_success
}

@test "os_change_dir_owner for new_user user" {
  local suffix
  suffix=$(date +%s)
  local -r username="new_user$suffix"
  run os_create_user "$username"
  assert_success
  mkdir -p "/tmp/$username"
  os_change_dir_owner "/tmp/$username" "$username"
  local owner=$(stat -c '%U' "/tmp/$username")
  assert_equal "$username" "$owner"
}

@test "os_change_dir_owner with sudo for new_user_sudo user" {
  local suffix
  suffix=$(date +%s)
  local -r username="new_user_sudo$suffix"
  run os_create_user "$username"
  assert_success
  mkdir -p "/tmp/$username"
  os_change_dir_owner "/tmp/$username" "$username" 'true'
  local owner=$(stat -c '%U' "/tmp/$username")
  assert_equal "$username" "$owner"
}
