#!/bin/bash

function create_mock_instance_with_tags {
  local readonly tag_key="$1"
  local readonly tag_value="$2"

  local mock_instance
  mock_instance=$(aws ec2 run-instances)

  local instance_id
  instance_id=$(echo "$mock_instance" | jq -r '.Instances[0].InstanceId')

  aws ec2 create-tags --resources "$instance_id" --tags Key="$tag_key",Value="$tag_value"

  echo -n "$instance_id"
}

function create_mock_asg {
  local readonly asg_name="$1"
  local readonly min_size="$2"
  local readonly max_size="$3"
  local readonly azs="$4"

  aws autoscaling create-launch-configuration --launch-configuration-name "$asg_name"
  aws autoscaling create-auto-scaling-group --auto-scaling-group-name "$asg_name" --min-size "$min_size" --max-size "$max_size" --availability-zones "$azs" --launch-configuration-name "$asg_name"
}