#!/usr/bin/env bash
# A collection of thin wrappers for direct calls to the AWS CLI and EC2 metadata API. These wrappers exist so that
# (a) it's more convenient to fetch specific info you need, such as an EC2 Instance's private IP and (b) so you can
# replace these helpers with mocks to do local testing or unit testing.
#
# See also: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html for info
# on the metadata endpoint at 169.254.169.254.

# The AWS EC2 Instance Metadata endpoint
readonly metadata_endpoint="http://169.254.169.254/latest"
# The AWS EC2 Instance Metadata dynamic endpoint
readonly metadata_dynamic_endpoint="http://169.254.169.254/latest/dynamic"
# The AWS EC2 Instance document endpoint
readonly instance_identity_endpoint="http://169.254.169.254/latest/dynamic/instance-identity/document"
# A convenience variable representing 3 hours, for use in requesting a token from the IMDSv2 endpoint
readonly three_hours_in_s=10800
# By default, we use Instance Metadata service version 2, which has been specially hardened against several attack vectors
default_instance_metadata_version="2"

# shellcheck source=./modules/bash-commons/src/assert.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"
# shellcheck source=./modules/bash-commons/src/log.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log.sh"

# If you must use Instance Metadata service version 1, you can do so by setting the environment variable:
# export GRUNTWORK_BASH_COMMONS_IMDSV="1"
function aws_get_instance_metadata_version_in_use {
  using=${GRUNTWORK_BASH_COMMONS_IMDSV:-$default_instance_metadata_version}
  assert_value_in_list "Instance Metadata service version in use" "$using" "1" "2"
  echo "$using"
}

# This function calls the Instance Metadata Service endpoint version 2 (IMDSv2) which is hardened against certain attack vectors.
# The endpoint returns a token that must be supplied on subsequent requests. This implementation fetches a new token
# for each transaction. See:
# https://aws.amazon.com/blogs/security/defense-in-depth-open-firewalls-reverse-proxies-ssrf-vulnerabilities-ec2-instance-metadata-service/
# for more information
function ec2_metadata_http_get {
  assert_not_empty "path" "$1"
  local -r path="$1"
  token=$(ec2_metadata_http_put $three_hours_in_s)
  curl "$metadata_endpoint/meta-data/$path" -H "X-aws-ec2-metadata-token: $token" \
    --silent --location --fail --show-error
}

function ec2_metadata_dynamic_http_get {
  assert_not_empty "path" "$1"
  local -r path="$1"
  token=$(ec2_metadata_http_put $three_hours_in_s)
  curl "$metadata_dynamic_endpoint/$path" -H "X-aws-ec2-metadata-token: $token" \
    --silent --location --fail --show-error
}

function ec2_metadata_http_put {
  # We allow callers to configure the ttl - if not provided it will default to 6 hours
  local ttl="$1"
  if [[ -z "$1" ]]; then
    ttl=21600
  elif [[ "$1" -gt 21600 ]]; then
    ttl=21600
  fi
  token=$(curl --silent --location --fail --show-error -X PUT "$metadata_endpoint/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: $ttl")
  echo "$token"
}

function ec2_instance_identity_field_get {
  local -r field="$1"
  token=$(ec2_metadata_http_put $three_hours_in_s)
  curl "$instance_identity_endpoint" -H "X-aws-ec2-metadata-token: $token" \
    --silent --location --fail --show-error | jq -r ".${field}"
}

function aws_lookup_path_in_instance_metadata {
  local -r path="$1"
    version_in_use=$(aws_get_instance_metadata_version_in_use)
  if [[ "$version_in_use" -eq 1 ]]; then
    aws_lookup_path_in_instance_metadata_v1 "$path"
  elif [[ "$version_in_use" -eq 2 ]]; then
    aws_lookup_path_in_instance_metadata_v2 "$path"
  fi
}

function aws_lookup_path_in_instance_metadata_v2 {
 assert_not_empty "path" "$path" "Must specify a metadata path to request"
 ec2_metadata_dynamic_http_get "$path"
}

# Look up the given path in the EC2 Instance metadata endpoint using IMDSv1
function aws_lookup_path_in_instance_metadata_v1 {
  local -r path="$1"
  curl --silent --show-error --location "http://169.254.169.254/latest/meta-data/$path/"
}

function aws_lookup_path_in_instance_dynamic_data {
 local -r path="$1"
 version_in_use=$(aws_get_instance_metadata_version_in_use)
 if [[ "$version_in_use" -eq 1 ]]; then
   aws_lookup_path_in_instance_dynamic_data_v1 "$path"
 elif [[ "$version_in_use" -eq 2 ]]; then
   aws_lookup_path_in_instance_dynamic_data_v2 "$path"
 fi
}

function aws_lookup_path_in_instance_dynamic_data_v2 {
 local -r path="$1"
 assert_not_empty "path" "$path" "Must specify a metadata dynamic path to request"
 ec2_metadata_dynamic
}

# Look up the given path in the EC2 Instance dynamic metadata endpoint using IMDSv1
function aws_lookup_path_in_instance_dynamic_data_v1 {
  local -r path="$1"
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
  local -r instance_id="$1"
  local -r instance_region="$2"

  aws ec2 describe-tags \
    --region "$instance_region" \
    --filters "Name=resource-type,Values=instance" "Name=resource-id,Values=$instance_id"
}

# Return the value of the $tag_key for the given EC2 Instance $instance_id
function aws_get_instance_tag_val {
  local -r tag_key="$1"
  local -r instance_id="$2"
  local -r instance_region="$3"

  local tags
  tags=$(aws_get_instance_tags "$instance_id" "$instance_region")

  local tag_val
  tag_val=$(echo "$tags" | jq -r ".Tags[] | select( .ResourceType == \"instance\" and .Key == \"$tag_key\") | .Value")

  echo "$tag_val"
}

# Return all ENIs attached to the current EC2 Instance
function aws_get_enis_for_instance {
  local -r instance_id="$1"
  local -r aws_region="$2"

  aws ec2 describe-network-interfaces --region "$aws_region" --filters "Name=attachment.instance-id,Values=$instance_id"
}

# Find all Elastic Network Interfaces (ENIs) that have a matching $tag_key=$tag_value
function aws_get_enis_for_tag {
  local -r tag_key="$1"
  local -r tag_value="$2"
  local -r aws_region="$3"

  aws ec2 describe-network-interfaces --region "$aws_region" --filters "Name=tag:$tag_key,Values=$tag_value"
}

# Given the $network_interfaces_output, return the ID of the ENI at the given $eni_index (zero-based)
#
# Example:
#   network_interfaces_output=$(aws_get_enis_for_this_ec2_instance)
#   aws_get_eni_id "$network_interfaces_output" 0
function aws_get_eni_id {
  local -r network_interfaces_output="$1"
  local -r eni_device_index="$2"

  assert_not_empty "network_interfaces_output" "$network_interfaces_output" "Value returned from AWS API describe-network-interfaces output"
  assert_not_empty "eni_device_index" "$eni_device_index"

  local num_enis
  num_enis=$(echo "$network_interfaces_output" | jq -r ".NetworkInterfaces | length")

  if [[ "$num_enis" -lt 1 ]]; then
    log_error "Expected to find at least 1 ENI in AWS API describe-network-interfaces output."
    exit 1
  fi

  if [[ "$num_enis" -lt "$eni_device_index" ]]; then
    log_error "Requested an ENI device-index out of range from describe-network-interfaces output."
    exit 1
  fi

  local eni_id
  eni_id=$(echo "$network_interfaces_output" | jq -r ".NetworkInterfaces[] | select(.Attachment.DeviceIndex == $eni_device_index).NetworkInterfaceId")

  assert_not_empty_or_null "$eni_id" "No ENI exists whose DeviceIndex property is $eni_device_index. Did you forget to create or attach an additional ENI?"

  echo "$eni_id"
}

# Given a $tag_key, return the corresponding tag_val for the ENI at the the given $eni_device_index (zero-based).
#
# Example:
#   network_interfaces_output=$(aws_get_enis_for_this_ec2_instance)
#   aws_get_eni_tag_val "$network_interfaces_output" 0 "DnsName"
function aws_get_eni_tag_val {
  local -r network_interfaces_output="$1"
  local -r eni_device_index="$2"
  local -r tag_key="$3"

  assert_not_empty "tag_key" "$tag_key"

  local eni_id
  eni_id="$(aws_get_eni_id "$network_interfaces_output" "$eni_device_index")"
  log_info "Looking up the value of the tag \"$tag_key\" for ENI $eni_id"

  local tag_val
  tag_val=$(echo "$network_interfaces_output" | jq -j ".NetworkInterfaces[] | select(.NetworkInterfaceId == \"$eni_id\").TagSet[] | select(.Key == \"$tag_key\").Value")

  assert_not_empty_or_null_warn "$tag_val" "Found empty value when looking up tag \"$tag_key\" for ENI $eni_id"

  echo "$tag_val"
}

# Return the *public* IP Address of for the ENI at the the given $eni_device_index (zero-based).
#
# Example:
#   network_interfaces_output=$(aws_get_enis_for_this_ec2_instance)
#   aws_get_eni_public_ip "$network_interfaces_output" 0
function aws_get_eni_public_ip {
  local -r network_interfaces_output="$1"
  local -r eni_device_index="$2"

  local eni_id
  eni_id="$(aws_get_eni_id "$network_interfaces_output" "$eni_device_index")"
  log_info "Looking up public IP address for ENI $eni_id"

  public_ip=$(echo "$network_interfaces_output" | jq -j ".NetworkInterfaces[] | select(.NetworkInterfaceId == \"$eni_id\").PrivateIpAddresses[0].Association.PublicIp")

  assert_not_empty_or_null "$public_ip" "No public IP address found for ENI $eni_id."

  echo "$public_ip"
}

# Return the *private* IP Address of for the ENI at the the given $eni_device_index (zero-based).
#
# Example:
#   network_interfaces_output=$(aws_get_enis_for_this_ec2_instance)
#   aws_get_eni_private_ip "$network_interfaces_output" 0
function aws_get_eni_private_ip {
  local -r network_interfaces_output="$1"
  local -r eni_device_index="$2"

  local eni_id
  eni_id="$(aws_get_eni_id "$network_interfaces_output" "$eni_device_index")"
  log_info "Looking up private IP address for ENI $eni_id"

  private_ip=$(echo "$network_interfaces_output" | jq -j ".NetworkInterfaces[] | select(.NetworkInterfaceId == \"$eni_id\").PrivateIpAddresses[0].PrivateIpAddress")

  echo "$private_ip"
}

# Return the private IP Address of the ENI attached to the given EC2 Instance
function aws_get_eni_private_ip_for_instance {
  local -r network_interfaces_output="$1"
  local -r instance_id="$2"

  local attached_network_interface
  attached_network_interface=$(echo "$network_interfaces_output" | jq -r ".NetworkInterfaces[] | select(.Attachment.InstanceId == \"$instance_id\")")

  echo "$attached_network_interface" | jq -r '.PrivateIpAddresses[0].PrivateIpAddress'
}

# Get the instances with a given tag and in a specific region. Returns JSON from the AWS CLI's describe-instances command.
function aws_get_instances_with_tag {
  local -r tag_key="$1"
  local -r tag_value="$2"
  local -r instance_region="$3"

  aws ec2 describe-instances \
    --region "$instance_region" \
    --filters "Name=tag:$tag_key,Values=$tag_value" "Name=instance-state-name,Values=pending,running"
}

# Describe the given ASG in the given region. Returns JSON from the AWS CLI's describe-auto-scaling-groups command.
function aws_describe_asg {
  local -r asg_name="$1"
  local -r aws_region="$2"

  aws autoscaling describe-auto-scaling-groups --region "$aws_region" --auto-scaling-group-names "$asg_name"
}

# Describe the EC2 Instances in the given ASG in the given region. Returns JSON from the AWS CLI's describe-instances
# command
function aws_describe_instances_in_asg {
  local -r asg_name="$1"
  local -r aws_region="$2"

  aws ec2 describe-instances --region "$aws_region" --filters "Name=tag:aws:autoscaling:groupName,Values=$asg_name" "Name=instance-state-name,Values=pending,running"
}
