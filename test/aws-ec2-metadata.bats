#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/../modules/bash-commons/src/aws.sh"
load "test-helper"
load "aws-helper"

readonly api_token="AQAEAArLzfm8TnzVoAFYcAnoJEyfLlx8itHCZvI9AY_OfCFiaYNK2w=="
readonly local_ipv4="11.22.33.44"
readonly public_ipv4="55.66.77.88"
readonly local_hostname="ip-10-251-50-12.ec2.internal"
readonly public_hostname="ec2-203-0-113-25.compute-1.amazonaws.com"
readonly instance_id="i-1234567890abcdef0"
readonly mock_region="us-west-1"
readonly availability_zone="${mock_region}b"

function setup {
  start_ec2_metadata_mock \
    "$api_token" \
    "$local_ipv4" \
    "$public_ipv4" \
    "$local_hostname" \
    "$public_hostname" \
    "$instance_id" \
    "$mock_region" \
    "$availability_zone"
}

function teardown {
  stop_ec2_metadata_mock
}

@test "aws_get_api_token" {
  run aws_get_api_token
  assert_success
  assert_output "$api_token"
}

@test "aws_get_instance_private_ip" {
  run aws_get_instance_private_ip
  assert_success
  assert_output "$local_ipv4"
}

@test "aws_get_instance_public_ip" {
  run aws_get_instance_public_ip
  assert_success
  assert_output "$public_ipv4"
}

@test "aws_get_instance_private_hostname" {
  run aws_get_instance_private_hostname
  assert_success
  assert_output "$local_hostname"
}

@test "aws_get_instance_public_hostname" {
  run aws_get_instance_public_hostname
  assert_success
  assert_output "$public_hostname"
}

@test "aws_get_instance_id" {
  run aws_get_instance_id
  assert_success
  assert_output "$instance_id"
}

@test "aws_get_instance_region" {
  run aws_get_instance_region
  assert_success
  assert_output "$mock_region"
}

@test "aws_get_ec2_instance_availability_zone" {
  run aws_get_ec2_instance_availability_zone
  assert_success
  assert_output "$availability_zone"
}

