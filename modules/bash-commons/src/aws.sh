#!/usr/bin/env bash
# A collection of thin wrappers for direct calls to the AWS CLI and EC2 metadata API. These wrappers exist so that
# (a) it's more convenient to fetch specific info you need, such as an EC2 Instance's private IP and (b) so you can
# replace these helpers with mocks to do local testing or unit testing.

set -e

# Look up the given path in the EC2 Instance metadata endpoint
function aws_lookup_path_in_instance_metadata {
  local readonly path="$1"
  curl --silent --show-error --location "http://169.254.169.254/latest/meta-data/$path/"
}

# Look up the given path in the EC2 Instance dynamic metadata endpoint
function aws_lookup_path_in_instance_dynamic_data {
  local readonly path="$1"
  curl --silent --show-error --location "http://169.254.169.254/latest/dynamic/$path/"
}

# Get the private IP address for this EC2 Instance
function aws_get_instance_private_ip {
  aws_lookup_path_in_instance_metadata "local-ipv4"
}

# Get the public IP address for this EC2 Instance
function aws_get_instance_public_ip {
  aws_lookup_path_in_instance_metadata "public-ipv4"
}

# Get the private hostname for this EC2 Instance
function aws_get_instance_private_hostname {
  aws_lookup_path_in_instance_metadata "local-hostname"
}

# Get the public hostname for this EC2 Instance
function aws_get_instance_public_hostname {
  aws_lookup_path_in_instance_metadata "public-hostname"
}

# Get the ID of this EC2 Instance
function aws_get_instance_id {
  aws_lookup_path_in_instance_metadata "instance-id"
}

# Get the region this EC2 Instance is deployed in
function aws_get_instance_region {
  aws_lookup_path_in_instance_dynamic_data "instance-identity/document" | jq -r ".region"
}

# Get the availability zone this EC2 Instance is deployed in
function aws_get_ec2_instance_availability_zone {
  aws_lookup_path_in_instance_metadata "placement/availability-zone"
}

# Get the tags for the given instance and region. Returns JSON from the AWS CLI's describe-tags command.
function aws_get_instance_tags {
  local readonly instance_id="$1"
  local readonly instance_region="$2"

  aws ec2 describe-tags \
    --region "$instance_region" \
    --filters "Name=resource-type,Values=instance" "Name=resource-id,Values=$instance_id"
}

# Get the instances with a given tag and in a specific region. Returns JSON from the AWS CLI's describe-instances command.
function aws_get_instances_with_tag {
  local readonly tag_key="$1"
  local readonly tag_value="$2"
  local readonly instance_region="$3"

  aws ec2 describe-instances \
    --region "$instance_region" \
    --filters "Name=tag:$tag_key,Values=$tag_value" "Name=instance-state-name,Values=pending,running"
}

# Describe the given ASG in the given region. Returns JSON from the AWS CLI's describe-auto-scaling-groups command.
function aws_describe_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  aws autoscaling describe-auto-scaling-groups --region "$aws_region" --auto-scaling-group-names "$asg_name"
}

# Describe the EC2 Instances in the given ASG in the given region. Returns JSON from the AWS CLI's describe-instances
# command
function aws_describe_instances_in_asg {
  local readonly asg_name="$1"
  local readonly aws_region="$2"

  aws ec2 describe-instances --region "$aws_region" --filters "Name=tag:aws:autoscaling:groupName,Values=$asg_name" "Name=instance-state-name,Values=pending,running"
}