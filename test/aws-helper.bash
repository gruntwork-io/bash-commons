#!/bin/bash

set -e

source "$BATS_TEST_DIRNAME/../modules/bash-commons/src/string.sh"

readonly MOTO_TMP_DIR="/tmp/moto"
readonly MOTO_PID_FILE_PATH="$MOTO_TMP_DIR/moto.pid"

readonly EC2_METADATA_MOCK_APP_PATH="$BATS_TEST_DIRNAME/ec2-metadata-mock/ec2-metadata-mock.py"
readonly EC2_METADATA_MOCK_TMP_DIR="/tmp/ec2-metadata-mock"
readonly EC2_METADATA_MOCK_PID_PATH="$EC2_METADATA_MOCK_TMP_DIR/ec2-metadata-mock.pid"
readonly EC2_METADATA_MOCK_LOG_FILE_PATH="$EC2_METADATA_MOCK_TMP_DIR/ec2-metadata-mock.log"

function start_ec2_metadata_mock {
  # Set env vars for ec2-metadata-mock
  export meta_data_local_ipv4="$1"
  export meta_data_public_ipv4="$2"
  export meta_data_local_hostname="$3"
  export meta_data_public_hostname="$4"
  export meta_data_instance_id="$5"
  local -r region="$6"
  export meta_data_placement__availability_zone="$7"
  export dynamic_data_instance_identity__document=$(cat <<END_HEREDOC
{
  "devpayProductCodes" : null,
  "marketplaceProductCodes" : [ "1abc2defghijklm3nopqrs4tu" ],
  "availabilityZone" : "$meta_data_placement__availability_zone",
  "privateIp" : "$meta_data_local_ipv4",
  "version" : "2017-09-30",
  "instanceId" : "$meta_data_instance_id",
  "billingProducts" : null,
  "instanceType" : "t2.micro",
  "accountId" : "123456789012",
  "imageId" : "ami-5fb8c835",
  "pendingTime" : "2016-11-19T16:32:11Z",
  "architecture" : "x86_64",
  "kernelId" : null,
  "ramdiskId" : null,
  "region" : "$region"
}
END_HEREDOC
)

  local config
  config=$(ifconfig)

  mkdir -p "$EC2_METADATA_MOCK_TMP_DIR"

  # Use ifconfig and iptables to allow us to run a mock server on 169.254.169.254 and on port 80. These steps are
  # based on https://github.com/NYTimes/mock-ec2-metadata. Note #1: we can't use that project directly as it doesn't
  # support most EC2 metadata endpoints. Note #2: try to make this code idempotent so we don't try to create the same
  # configuration multiple times.
  if ! string_multiline_contains "$config" "lo:1"; then
    ifconfig lo:1 inet 169.254.169.254 netmask 255.255.255.255 up
    echo 1 > /proc/sys/net/ipv4/ip_forward
    iptables -t nat -A OUTPUT -p tcp -d 169.254.169.254/32 --dport 80  -j DNAT --to-destination 169.254.169.254:8111
    iptables-save
  fi

  # Start ec2-metadata-mock if it isn't already running
  if [[ ! -f "$EC2_METADATA_MOCK_PID_PATH" ]]; then
    FLASK_APP="$EC2_METADATA_MOCK_APP_PATH" flask run --host=0.0.0.0 --port=8111 2>&1  > "$EC2_METADATA_MOCK_LOG_FILE_PATH" &
    echo "$!" > "$EC2_METADATA_MOCK_PID_PATH"

    # Sleep a bit to give Flask a chance to start
    sleep 1
  fi
}

function stop_ec2_metadata_mock {
  # Stop ec2-metadata-mock if it's running
  if [[ -f "$EC2_METADATA_MOCK_PID_PATH" ]]; then
    local -r pid=$(cat "$EC2_METADATA_MOCK_PID_PATH")
    kill "$pid" 2>&1 > "$EC2_METADATA_MOCK_LOG_FILE_PATH"
    rm -f "$EC2_METADATA_MOCK_PID_PATH"

    # Sleep a bit to give Flask a chance to stop
    sleep 1
  fi
}

# Source the mock version of aws.sh to override the real one so we don't depend on EC2 metadata. For some reason, with
# bats, trying to run both moto and the mock ec2 metadata services in the background causes the latter to hang. This
# may be related to https://github.com/sstephenson/bats/issues/80, but none of the workarounds seem to help, so for now,
# tests that need both should load the real moto, but use this mock for aws.sh.
function load_aws_mock {
  export mock_instance_tags="$1"
  export mock_asg="$2"
  export mock_instances_in_asg="$3"

  source "$BATS_TEST_DIRNAME/aws-mock/aws.sh"
}

function start_moto {
  mkdir -p "$MOTO_TMP_DIR"

  # Start moto server if it isn't already running
  if [[ ! -f "$MOTO_PID_FILE_PATH" ]]; then
    moto_server &
    echo "$!" > "$MOTO_PID_FILE_PATH"

    # Sleep a bit to give moto a chance to start
    sleep 1
  fi
}

function stop_moto {
  # Stop moto if it's running
  if [[ -f "$MOTO_PID_FILE_PATH" ]]; then
    local -r pid=$(cat "$MOTO_PID_FILE_PATH")
    kill "$pid" 2>&1 > /dev/null
    rm -f "$MOTO_PID_FILE_PATH"

    # Sleep a bit to give moto a chance to stop
    sleep 1
  fi
}

function create_mock_instance_with_tags {
  local -r tag_key="$1"
  local -r tag_value="$2"

  local mock_instance
  mock_instance=$(aws ec2 run-instances)

  local instance_id
  instance_id=$(echo "$mock_instance" | jq -r '.Instances[0].InstanceId')

  aws ec2 create-tags --resources "$instance_id" --tags Key="$tag_key",Value="$tag_value"

  echo -n "$instance_id"
}

function create_mock_asg {
  local -r asg_name="$1"
  local -r min_size="$2"
  local -r max_size="$3"
  local -r azs="$4"

  aws autoscaling create-launch-configuration --launch-configuration-name "$asg_name" --image-id ami-fake --instance-type t3.micro
  aws autoscaling create-auto-scaling-group --auto-scaling-group-name "$asg_name" --min-size "$min_size" --max-size "$max_size" --availability-zones "$azs" --launch-configuration-name "$asg_name"
}
