#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/../modules/bash-commons/src/aws.sh"
load "test-helper"
load "aws-helper"

function setup {
  start_moto
}

function teardown {
  stop_moto
}

@test "aws_get_instance_tags empty" {
  run aws_get_instance_tags "fake-id" "us-east-1"
  assert_success

  local -r expected=$(cat <<END_HEREDOC
{
  "Tags": []
}
END_HEREDOC
)

  assert_output_json "$expected"
}

@test "aws_get_instance_tags non-empty" {
  local -r tag_key="foo"
  local -r tag_value="bar"

  local instance_id
  instance_id=$(create_mock_instance_with_tags "$tag_key" "$tag_value")

  run aws_get_instance_tags "$instance_id" "us-east-1"
  assert_success

  local -r expected=$(cat <<END_HEREDOC
{
   "Tags": [
     {
       "ResourceType": "instance",
       "ResourceId": "$instance_id",
       "Value": "$tag_value",
       "Key": "$tag_key"
     }
   ]
 }
END_HEREDOC
)

  assert_output_json "$expected"
}

@test "aws_get_instance_tag_val non-empty" {
  local -r tag_key="foo"
  local -r tag_value="bar"

  local instance_id
  instance_id=$(create_mock_instance_with_tags "$tag_key" "$tag_value")

  run aws_get_instance_tag_val "$tag_key" "$instance_id" "us-east-1"
  assert_success

  local -r expected="$tag_value"

  assert_output "$expected"
}

@test "aws_describe_asg empty" {
  run aws_describe_asg "fake-asg-name" "us-east-1"
  assert_success

  local -r expected=$(cat <<END_HEREDOC
{
  "AutoScalingGroups": []
}
END_HEREDOC
)

  assert_output_json "$expected"
}

@test "aws_describe_asg non-empty" {
  local -r asg_name="foo"
  local -r min_size=1
  local -r max_size=3
  local -r region="us-east-1"
  local -r azs="${region}a"

  create_mock_asg "$asg_name" "$min_size" "$max_size" "$azs"

  run aws_describe_asg "$asg_name" "$region"
  assert_success

  local actual_asg_name
  actual_asg_name=$(echo "$output" | jq -r '.AutoScalingGroups[0].AutoScalingGroupName')
  assert_equal "$asg_name" "$actual_asg_name"

  local actual_min_size
  actual_min_size=$(echo "$output" | jq -r '.AutoScalingGroups[0].MinSize')
  assert_equal "$min_size" "$actual_min_size"

  local actual_max_size
  actual_max_size=$(echo "$output" | jq -r '.AutoScalingGroups[0].MaxSize')
  assert_equal "$max_size" "$actual_max_size"
}

@test "aws_describe_instances_in_asg empty" {
  run aws_describe_instances_in_asg "fake-asg-name" "us-east-1"
  assert_success

  local -r expected=$(cat <<END_HEREDOC
{
  "Reservations": []
}
END_HEREDOC
)

  assert_output_json "$expected"
}

@test "aws_describe_instances_in_asg non-empty" {
  local -r asg_name="foo"
  local -r min_size=1
  local -r max_size=3
  local -r region="us-east-1"
  local -r azs="${region}a"

  create_mock_asg "$asg_name" "$min_size" "$max_size" "$azs"

  run aws_describe_instances_in_asg "$asg_name" "$region"
  assert_success

  local num_instances
  num_instances=$(echo "$output" | jq -r '.Reservations | length')
  assert_greater_than "$num_instances" 0
}

@test "aws_get_instances_with_tag empty" {
  run aws_get_instances_with_tag "Name" "Value" "us-east-1"
  assert_success

  local -r expected=$(cat <<END_HEREDOC
{
  "Reservations": []
}
END_HEREDOC
)

  assert_output_json "$expected"
}

@test "aws_get_instances_with_tag non-empty" {
  local -r tag_key="Name"
  local -r tag_value="Value"
  local -r region="us-east-1"

  create_mock_instance_with_tags "$tag_key" "$tag_value"
  run aws_get_instances_with_tag "$tag_key" "$tag_value" "$region"
  assert_success

  local num_instances
  num_instances=$(echo "$output" | jq -r '.Reservations | length')
  assert_greater_than "$num_instances" 0
}
