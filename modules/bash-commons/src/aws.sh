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
# The AWS EC2 Instance IMDSv2 Token endpoint
readonly imdsv2_token_endpoint="http://169.254.169.254/latest/api/token"
# A convenience variable representing 3 hours, for use in requesting a token from the IMDSv2 endpoint
readonly three_hours_in_s=10800
# A convenience variable representing 6 hours, which is the maximum configurable session duration when requesting
# a token from IMDSv2
readonly six_hours_in_s=21600

# shellcheck source=./modules/bash-commons/src/assert.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"
# shellcheck source=./modules/bash-commons/src/log.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log.sh"

# Set variable to an empty string if it is unbound to prevent "unbound variable".
export GRUNTWORK_BASH_COMMONS_IMDS_VERSION=${GRUNTWORK_BASH_COMMONS_IMDS_VERSION-}
# Set default variable to version "2" if nothing is set.
export default_instance_metadata_version=${default_instance_metadata_version-"2"}

# Detect if the instance has IMDS available and return what version is available.
# Users can always specify the version of the Instance Metadata Service they want bash-commons
# to consult by setting the environment variable GRUNTWORK_BASH_COMMONS_IMDS_VERSION.
# If set, GRUNTWORK_BASH_COMMONS_IMDS_VERSION will override default_instance_metadata_version.
# Defaults to IMDSv2 since that is now available by default on instances.
function aws_check_metadata_availability {
  version_to_check=${GRUNTWORK_BASH_COMMONS_IMDS_VERSION:-$default_instance_metadata_version}
  if [[ "${version_to_check}" == "" ]]; then
    echo "No IMDS version specified, unable to check metadata availability."
    return 9
  fi

  if [[ "${version_to_check}" == "2" ]]; then
    curl_exit_code=$(sudo curl -s -o /dev/null -X PUT ${imdsv2_token_endpoint} -H "X-aws-ec2-metadata-token-ttl-seconds: 10"; echo $?)
    if [ ${curl_exit_code} -eq 0 ]; then
      default_instance_metadata_version="2"
    elif [ ${curl_exit_code} -eq 7 ]; then
      echo "Check for IMDSv2 failed. IMDS endpoint connection refused."
      default_instance_metadata_version="0"
    else
      echo "IMDS endpoint connection failed for an unknown reason with error code: ${finish_code}"
      default_instance_metadata_version="0"
    fi
  fi

  if [[ "${version_to_check}" == "1" ]]; then
    curl_exit_code=$(sudo curl -s -o /dev/null $metadata_endpoint; echo $?)
    if [ ${curl_exit_code} -eq 0 ]; then
      default_instance_metadata_version="1"
    elif [ ${curl_exit_code} -eq 7 ]; then
      echo "Check for IMDSv1 and v2 failed. IMDS endpoint connection refused."
      default_instance_metadata_version="0"
    else
      echo "IMDS endpoint connection failed for an unknown reason with error code: ${finish_code}"
      default_instance_metadata_version="0"
    fi
  fi
  
  # returns "2" if IMDSv2 is available, "1" if v2 is not but v1 is, returns "0" if neither are available (i.e. endpoint is disabled or blocked)
  echo $default_instance_metadata_version
}

# Check if IMDS Metadata Endpoint is available.  This is required for most of the functions in this script.
imds_available=$(aws_check_metadata_availability)
if [[ "${imds_available}" == 9 ]]; then
  echo "No IMDS Version declared.  This should not be possible because this script sets a default of 2.  Check to see if it was unset somewhere."
elif [[ "${imds_available}" == 0 ]]; then
  echo "IMDS Metadata Endpoint is not available.  Script cannot continue without the Endpoint."
fi

# AWS and Gruntwork recommend use of the Instance Metadata Service version 2 whenever possible. Although
# IMDSv1 is still supported and considered fully secure by AWS, IMDSv2 features special hardening against
# specific threat vectors. Read more at:
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html
#
# The default is now version 2, but if you prefer to use Instance Metadata service version 1, you can do
# so by setting the environment variable:
# export GRUNTWORK_BASH_COMMONS_IMDS_VERSION="1"
# This function will override the default based on the contents of that variable if it is set.
function aws_get_instance_metadata_version_in_use {
  using=${GRUNTWORK_BASH_COMMONS_IMDS_VERSION:-$default_instance_metadata_version}
  assert_value_in_list "Instance Metadata service version in use" "$using" "1" "2"
  echo "$using"
}

##################################################################################
# Shim functions to support both IMDSv1 and IMDSv2 simultaneously
##################################################################################
# The following functions aim to support backward compatibility with IMDSv1 by
# maintaining the arity of all previous function calls, but using $default_instance_metadata_version
# to determine which implementation's code path to follow

# This function has been modified to simultaneously support Instance Metadata service versions 1 and 2
# This is due to the fact that we will need to operate in a split-brain mode while all our dependent
# modules are being updated to use IMDSv2.
#
# Version 2 is the default, but can be overridden by setting:
# env var GRUNTWORK_BASH_COMMONS_IMDS_VERSION=1
function aws_lookup_path_in_instance_metadata {
  local -r path="$1"
  version_in_use=$(aws_get_instance_metadata_version_in_use)
  if [[ "$version_in_use" -eq 1 ]]; then
    aws_lookup_path_in_instance_metadata_v1 "$path"
  elif [[ "$version_in_use" -eq 2 ]]; then
    aws_lookup_path_in_instance_metadata_v2 "$path"
  fi
}

# This function has been modified to simultaneously support Instance Metadata service versions 1 and 2
# This is due to the fact that we will need to operate in a split-brain mode while all our dependent
# modules are being updated to use IMDSv2.
#
# Version 2 is the default, but can be overridden by setting:
# env var GRUNTWORK_BASH_COMMONS_IMDS_VERSION=1
function aws_lookup_path_in_instance_dynamic_data {
 local -r path="$1"
 version_in_use=$(aws_get_instance_metadata_version_in_use)
 if [[ "$version_in_use" -eq 1 ]]; then
   aws_lookup_path_in_instance_dynamic_data_v1 "$path"
 elif [[ "$version_in_use" -eq 2 ]]; then
   aws_lookup_path_in_instance_dynamic_data_v2 "$path"
 fi
}

##################################################################################
# Instance Metadata Service Version 1 implementation functions
##################################################################################
# The following functions implement calls to Instance Metadata Service version 1,
# meaning that they do not retrieve or present the tokens returned and expected by
# IMDSv2

# This function uses Instance Metadata service version 1. It requests the supplied
# path from the endpoint, but does not use the token-based authorization scheme.
function aws_lookup_path_in_instance_metadata_v1 {
  local -r path="$1"
  curl --silent --show-error --location "http://169.254.169.254/latest/meta-data/$path/"
}

# Look up the given path in the EC2 Instance dynamic metadata endpoint using IMDSv1
function aws_lookup_path_in_instance_dynamic_data_v1 {
  local -r path="$1"
  curl --silent --show-error --location "http://169.254.169.254/latest/dynamic/$path/"
}

##################################################################################
# Instance Metadata Service Version 2 functions
##################################################################################
# The following functions use IMDSv2, meaning they request and present IMDSv2
# tokens when making requests to IMDS.

# This function calls the Instance Metadata Service endpoint version 2 (IMDSv2)
# which is hardened against certain attack vectors. The endpoint returns a token
# that must be supplied on subsequent requests. This implementation fetches a new
# token for each transaction. See:
# https://aws.amazon.com/blogs/security/defense-in-depth-open-firewalls-reverse-proxies-ssrf-vulnerabilities-ec2-instance-metadata-service/
# for more information
function ec2_metadata_http_get {
  assert_not_empty "path" "$1"
  local -r path="$1"
  # We allow callers to configure the ttl - if not provided it will default to 6 hours
  local ttl=""
  ttl=$(configure_imdsv2_ttl "$2")
  token=$(ec2_metadata_http_put "$ttl")
  curl "$metadata_endpoint/meta-data/$path" -H "X-aws-ec2-metadata-token: $token" \
    --silent --location --fail --show-error
}

# This function uses Instance Metadata service version 2. It requests the supplied
# path from the dynamic endpoint.
function ec2_metadata_dynamic_http_get {
  assert_not_empty "path" "$1"
  local -r path="$1"
  # We allow callers to configure the ttl - if not provided it will default to 6 hours
  local ttl=""
  ttl=$(configure_imdsv2_ttl "$2")
  token=$(ec2_metadata_http_put "$three_hours_in_s")
  curl "$metadata_dynamic_endpoint/$path" -H "X-aws-ec2-metadata-token: $token" \
    --silent --location --fail --show-error
}

# This function uses Instance Metadata Service version 2. It retrieves a token from the IMDSv2
# endpoint, which can be presented during subequent requests to the IMDSv2 endpoints.

# This function accepts a conifgurable TTL for the IMDSv2 token it requests. If a TTL is not supplied,
# this function will default to the maximum IMDSv2 session duration which is 6 hours.
function ec2_metadata_http_put {
  # We allow callers to configure the ttl - if not provided it will default to 6 hours
  local ttl=""
  ttl=$(configure_imdsv2_ttl "$2")
  token=$(curl --silent --location --fail --show-error -X PUT "$metadata_endpoint/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: $ttl")
  echo "$token"
}

# This function uses Instance Metadata Service version 2. It retrieves the field of the supplied name
# from the Instance Metadata Service's identity document for the given EC2 instance and returns
# its value.
#
# This function uses Instance Metadata Service version 2. It accepts a configurable TTL
# for the IMDSv2 token it requests, and it returns the token to the caller. If a TTL
# is not supplied, this function will default to the maximum IMDSv2 session duration which is 6 hours.
function ec2_instance_identity_field_get {
  local -r field="$1"
  local ttl=""
  ttl=$(configure_imdsv2_ttl "$2")
  token=$(ec2_metadata_http_put "$ttl")
  curl "$instance_identity_endpoint" -H "X-aws-ec2-metadata-token: $token" \
    --silent --location --fail --show-error | jq -r ".${field}"
}

# This is a convenience function for setting a TTL, and falling back to sensible defaults
# when the value is either not supplied or out of bounds.
function configure_imdsv2_ttl {
 local ttl="$1"
 if [[ -z "$1" ]]; then
   ttl="$six_hours_in_s"
 elif (( "$1" > "$six_hours_in_s" )); then
   log_error "IMDSv2 token ttl maximum is 21600 seconds / 6 hours. Falling back to max session duration of 6 hours."
   ttl=21600
 fi
 echo "$ttl"
}

# This function uses Instance Metadata version 2.It requests the supplied path from
# the endpoint, leveraging the token-based authorization scheme.
function aws_lookup_path_in_instance_metadata_v2 {
 assert_not_empty "path" "$path" "Must specify a metadata path to request"
 ec2_metadata_http_get "$path"
}

# This function uses Instance Metadata version 2. It requests the specified path from
# the IMDS dynamic endpont
function aws_lookup_path_in_instance_dynamic_data_v2 {
 local -r path="$1"
 assert_not_empty "path" "$path" "Must specify a metadata dynamic path to request"
 ec2_metadata_dynamic_http_get "$path"
}

##################################################################################
# IMDS convenience functions
##################################################################################
# The following functions will use either IMDSv1 or IMDSv2, depending on the value
# of $default_instance_metadata_version, which defaults to 1 but can be overridden
# by setting the environment variable:
# export GRUNTWORK_BASH_COMMONS_IMDS_VERSION=2
# This is because these functions call out to the shim functions that determine which
# underlying implementation (IMDSv1 or IMDSv2) to use

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

##################################################################################
# Miscellaneous AWS CLI functions
##################################################################################
# The following functions leverage the AWS CLI, so their use of the Instance Metadata Service
# is governed by the version of the AWS CLI that is installed on a given system.
# Note that AWS CLI v2+ uses IMDSv2. Learn more at:
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html

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

# Assert that we're currently running on an EC2 instance
function assert_is_ec2_instance {
  local token
  token=$(ec2_metadata_http_put 1)
  [[ -n "$token" ]]
}
