#!/usr/bin/env bash
# A collection of "high level" wrappers for the AWS CLI and EC2 metadata to simplify common tasks such as looking up
# tags or IPs for EC2 Instances. Note that these wrappers handle all the data processing and logic, whereas all the
# direct calls to the AWS CLI and EC2 metadata endpoints are delegated to aws.sh to make unit testing easier.

# shellcheck source=./modules/bash-commons/src/log.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log.sh"
# shellcheck source=./modules/bash-commons/src/aws.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/aws.sh"
# shellcheck source=./modules/bash-commons/src/assert.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

# Get the name of the ASG this EC2 Instance is in. This is done by looking up the instance's tags. This method will
# wait up until the specified number of retries if the tags or instances are not yet available.
function aws_wrapper_get_asg_name {
  local -r max_retries="$1"
  local -r sleep_between_retries="$2"

  local instance_id
  instance_id=$(aws_get_instance_id)

  local instance_region
  instance_region=$(aws_get_instance_region)

  aws_wrapper_get_instance_tag "$instance_id" "$instance_region" "aws:autoscaling:groupName" "$max_retries" "$sleep_between_retries"
}

# Look up the tags for the specified Instance and extract the value for the specified tag key
function aws_wrapper_get_instance_tag {
  local -r instance_id="$1"
  local -r instance_region="$2"
  local -r tag_key="$3"
  local -r max_retries="${4:-60}"
  local -r sleep_between_retries="${5:-5}"

  for (( i=0; i<"$max_retries"; i++ )); do
    local tags
    tags=$(aws_wrapper_wait_for_instance_tags "$instance_id" "$instance_region" "$max_retries" "$sleep_between_retries")
    assert_not_empty_or_null "$tags" "tags for Instance $instance_id in $instance_region"

    local tag_value
    tag_value=$(echo "$tags" | jq -r ".Tags[] | select(.Key == \"$tag_key\") | .Value")

    if string_is_empty_or_null "$tag_value"; then
      log_warn "Instance $instance_id in $instance_region does not yet seem to have tag $tag_key. Will sleep for $sleep_between_retries seconds and check again."
      sleep "$sleep_between_retries"
    else
      log_info "Found value '$tag_value' for tag $tag_key for Instance $instance_id in $instance_region"
      echo -n "$tag_value"
      return
    fi
  done

  log_error "Could not find value for tag $tag_key for Instance $instance_id in $instance_region after $max_retries retries."
  exit 1
}

# Get the tags for the current EC2 Instance. Tags may take time to propagate, so this method will retry until the tags
# are available. Once tags are available, this method will return JSON in the format returned by the AWS CLI
# describe-tags command.
function aws_wrapper_wait_for_instance_tags {
  local -r instance_id="$1"
  local -r instance_region="$2"
  local -r max_retries="${3:-60}"
  local -r sleep_between_retries="${4:-5}"

  log_info "Looking up tags for Instance $instance_id in $instance_region"

  for (( i=0; i<"$max_retries"; i++ )); do
    local tags
    tags=$(aws_get_instance_tags "$instance_id" "$instance_region")

    local count_tags
    count_tags=$(echo "$tags" | jq -r ".Tags? | length")
    log_info "Found $count_tags tags for $instance_id."

    if [[ "$count_tags" -gt 0 ]]; then
      echo -n "$tags"
      return
    else
      log_warn "Tags for Instance $instance_id must not have propagated yet. Will sleep for $sleep_between_retries seconds and check again."
      sleep "$sleep_between_retries"
    fi
  done

  log_error "Could not find tags for Instance $instance_id in $instance_region after $max_retries retries."
  exit 1
}

# Get the desired capacity of the ASG with the given name in the given region
function aws_wrapper_get_asg_size {
  local -r asg_name="$1"
  local -r aws_region="$2"
  local -r max_retries="${3:-60}"
  local -r sleep_between_retries="${4:-5}"

  for (( i=0; i<"$max_retries"; i++ )); do
    log_info "Looking up the size of the Auto Scaling Group $asg_name in $aws_region"

    local asg_json
    asg_json=$(aws_describe_asg "$asg_name" "$aws_region")

    local desired_capacity
    desired_capacity=$(echo "$asg_json" | jq -r '.AutoScalingGroups[0]?.DesiredCapacity')

    if string_is_empty_or_null "$desired_capacity"; then
      log_warn "Could not find desired capacity for ASG $asg_name. Perhaps the ASG has not been created yet? Will sleep for $sleep_between_retries and check again. AWS response:\n$asg_json"
      sleep "$sleep_between_retries"
    else
      echo -n "$desired_capacity"
      return
    fi
  done

  log_error "Could not find size of ASG $asg_name after $max_retries retries."
  exit 1
}

# Describe the running instances in the given ASG and region. This method will retry until it is able to get the
# information for the number of instances that are defined in the ASG's DesiredCapacity. This ensures the method waits
# until all the Instances have booted. Once all instances are ready, this method returns JSON from the AWS CLI's
# describe-instances command.
function aws_wrapper_wait_for_instances_in_asg {
  local -r asg_name="$1"
  local -r aws_region="$2"
  local -r max_retries="${3:-60}"
  local -r sleep_between_retries="${4:-5}"

  local asg_size
  asg_size=$(aws_wrapper_get_asg_size "$asg_name" "$aws_region" "$max_retries" "$sleep_between_retries")
  assert_not_empty_or_null "$asg_size" "size of ASG $asg_name in $aws_region"

  log_info "Looking up Instances in ASG $asg_name in $aws_region"
  for (( i=0; i<"$max_retries"; i++ )); do
    local instances
    instances=$(aws_describe_instances_in_asg "$asg_name" "$aws_region")

    local count_instances
    count_instances=$(echo "$instances" | jq -r "[.Reservations[].Instances[].InstanceId] | length")

    log_info "Found $count_instances / $asg_size Instances in ASG $asg_name in $aws_region."

    if [[ "$count_instances" -ge "$asg_size" ]]; then
      echo "$instances"
      return
    else
      log_warn "Will sleep for $sleep_between_retries seconds and try again."
      sleep "$sleep_between_retries"
    fi
  done

  log_error "Could not find all $asg_size Instances in ASG $asg_name in $aws_region after $max_retries retries."
  exit 1
}

# Return a space-separated list of IPs in the given ASG. If use_public_ips is "true", these will be the public IPs;
# otherwise, these will be the private IPs.
function aws_wrapper_get_ips_in_asg {
  local -r asg_name="$1"
  local -r aws_region="$2"
  local -r use_public_ips="$3"
  local -r max_retries="${4:-60}"
  local -r sleep_between_retries="${5:-5}"

  local instances
  instances=$(aws_wrapper_wait_for_instances_in_asg "$asg_name" "$aws_region" "$max_retries" "$sleep_between_retries")
  assert_not_empty_or_null "$instances" "Get info about Instances in ASG $asg_name in $aws_region"

  local -r ip_param=$([[ "$use_public_ips" == "true" ]] && echo "PublicIpAddress" || echo "PrivateIpAddress")
  echo "$instances" | jq -r ".Reservations[].Instances[].$ip_param"
}

# Return a space-separated list of IPs belonging to instances with specific tag values.
# If use_public_ips is "true", these will be the public IPs; otherwise, these will be the private IPs.
function aws_wrapper_get_ips_with_tag {
  local -r tag_key="$1"
  local -r tag_value="$2"
  local -r aws_region="$3"
  local -r use_public_ips="$4"

  local instances
  instances=$(aws_get_instances_with_tag "$tag_key" "$tag_value" "$aws_region")

  local -r ip_param=$([[ "$use_public_ips" == "true" ]] && echo "PublicIpAddress" || echo "PrivateIpAddress")
  echo "$instances" | jq -r ".Reservations[].Instances[].$ip_param"
}

# Return a space-separated list of hostnames in the given ASG. If use_public_hostnames is "true", these will be the
# public hostnames; otherwise, these will be the private hostnames.
function aws_wrapper_get_hostnames_in_asg {
  local -r asg_name="$1"
  local -r aws_region="$2"
  local -r use_public_hostnames="$3"
  local -r max_retries="${4:-60}"
  local -r sleep_between_retries="${5:-5}"

  local instances
  instances=$(aws_wrapper_wait_for_instances_in_asg "$asg_name" "$aws_region" "$max_retries" "$sleep_between_retries")
  assert_not_empty_or_null "$instances" "Get info about Instances in ASG $asg_name in $aws_region"

  local -r hostname_param=$([[ "$use_public_hostnames" == "true" ]] && echo "PublicDnsName" || echo "PrivateDnsName")
  echo "$instances" | jq -r ".Reservations[].Instances[].$hostname_param"
}

# Get the hostname to use for this EC2 Instance. Use the public hostname if the first argument is true and the private
# hostname otherwise.
function aws_wrapper_get_hostname {
  local -r use_public_hostname="$1"

  if [[ "$use_public_hostname" == "true" ]]; then
    log_info "Using public hostname as instance address"
    aws_get_instance_public_hostname
  else
    log_info "Using private hostname as instance address"
    aws_get_instance_private_hostname
  fi
}

# Calculates a "rally point" instance in an ASG and returns its hostname. This is a deterministic way for the instances in an ASG to all pick the same single instance to perform some action: e.g., this instance could become the leader in a cluster or run some initialization script that should only be run once for the entire ASG. Under the hood, this method picks the instance in the ASG with the earliest launch time; in the case of ties, the instance with the earliest instance ID (lexicographically) is returned. This method assumes jq is installed.
function aws_wrapper_get_asg_rally_point {
  local -r asg_name="$1"
  local -r aws_region="$2"
  local -r use_public_hostname="$3"
  local -r retries="${4:-60}"
  local -r sleep_between_retries="${5:-5}"

  log_info "Calculating rally point for ASG $asg_name in $aws_region"

  local instances
  log_info "Waiting for all instances to be available..."
  instances=$(aws_wrapper_wait_for_instances_in_asg $asg_name $aws_region $retries $sleep_between_retries)
  assert_not_empty_or_null "$instances" "Wait for instances in ASG $asg_name in $aws_region"

  local rally_point
  rally_point=$(echo "$instances" | jq -r '[.Reservations[].Instances[]] | sort_by(.LaunchTime, .InstanceId) | .[0]')
  assert_not_empty_or_null "$rally_point" "Select rally point server in ASG $asg_name"

  local hostname_field=".PrivateDnsName"
  if [[ "$use_public_hostname" == "true" ]]; then
    hostname_field=".PublicDnsName"
  fi

  log_info "Hostname field is $hostname_field"

  local hostname
  hostname=$(echo "$rally_point" | jq -r "$hostname_field")
  assert_not_empty_or_null "$hostname" "Get hostname from field $hostname_field for rally point in $asg_name: $rally_point"
  
  echo -n "$hostname"
}
