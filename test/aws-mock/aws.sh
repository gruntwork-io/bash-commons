#!/bin/bash
# A mock version of aws.sh that returns hard-coded values and values from environment variables instead of making real
# API calls to AWS or the EC2 metadata service.

set -e

# Get a API session token
function aws_get_api_token {
  echo -n "AQAEAArLzfm8TnzVoAFYcAnoJEyfLlx8itHCZvI9AY_OfCFiaYNK2w=="
}

# Get the private IP address for this EC2 Instance
function aws_get_instance_private_ip {
  echo -n "11.22.33.44"
}

# Get the public IP address for this EC2 Instance
function aws_get_instance_public_ip {
  echo -n "55.66.77.88"
}

# Get the private hostname for this EC2 Instance
function aws_get_instance_private_hostname {
  echo -n "ip-10-251-50-12.ec2.internal"
}

# Get the public hostname for this EC2 Instance
function aws_get_instance_public_hostname {
  echo -n "ec2-203-0-113-25.compute-1.amazonaws.com"
}

# Get the ID of this EC2 Instance
function aws_get_instance_id {
  echo -n "i-1234567890abcdef0"
}

# Get the region this EC2 Instance is deployed in
function aws_get_instance_region {
  echo -n "us-east-1"
}

# Get the availability zone this EC2 Instance is deployed in
function aws_get_ec2_instance_availability_zone {
  echo -n "us-east-1b"
}

# Get the tags for the given instance and region. Returns JSON from the AWS CLI's describe-tags command.
function aws_get_instance_tags {
  local readonly instance_id="$1"
  local readonly instance_region="$2"

  echo -n "$mock_instance_tags"
}

# Describe the given ASG in the given region. Returns JSON from the AWS CLI's describe-auto-scaling-groups command.
function aws_describe_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  echo -n "$mock_asg"
}

# Describe the EC2 Instances in the given ASG in the given region. Returns JSON from the AWS CLI's describe-instances
# command
function aws_describe_instances_in_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  echo -n "$mock_instances_in_asg"
}
