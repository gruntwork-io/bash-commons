#!/usr/bin/env bats

readonly bash_commons_src_path="$BATS_TEST_DIRNAME/../modules/bash-commons/src"
source "$bash_commons_src_path/aws.sh"
source "$bash_commons_src_path/string.sh"
load "test-helper"

readonly EC2_METADATA_MOCK_APP_PATH="$BATS_TEST_DIRNAME/ec2-metadata-mock/ec2-metadata-mock.py"
readonly EC2_METADATA_MOCK_TMP_DIR="/tmp/ec2-metadata-mock"
readonly EC2_METADATA_MOCK_PID_PATH="$EC2_METADATA_MOCK_TMP_DIR/ec2-metadata-mock.pid"
readonly EC2_METADATA_MOCK_LOG_FILE_PATH="$EC2_METADATA_MOCK_TMP_DIR/ec2-metadata-mock.log"

# Set env vars for ec2-metadata-mock
export meta_data_local_ipv4="11.22.33.44"
export meta_data_public_ipv4="55.66.77.88"
export meta_data_local_hostname="ip-10-251-50-12.ec2.internal"
export meta_data_public_hostname="ec2-203-0-113-25.compute-1.amazonaws.com"
export meta_data_instance_id="i-1234567890abcdef0"

readonly mock_region="us-west-1"
export meta_data_placement__availability_zone="${mock_region}b"
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
  "region" : "$mock_region"
}
END_HEREDOC
)

# Configure the server so we can run a mock EC2 metadata endpoint on port 80 with the metadata endpoint's special IP.
function setup {
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
    FLASK_APP="$EC2_METADATA_MOCK_APP_PATH" flask run --host=0.0.0.0 --port=8111 2>&1 > "$EC2_METADATA_MOCK_LOG_FILE_PATH" &
    echo "$!" > "$EC2_METADATA_MOCK_PID_PATH"

    # Sleep a bit to give Flask a chance to start
    sleep 1
  fi
}

function teardown {
  # Stop ec2-metadata-mock if it's running
  if [[ -f "$EC2_METADATA_MOCK_PID_PATH" ]]; then
    local readonly pid=$(cat "$EC2_METADATA_MOCK_PID_PATH")
    kill "$pid" 2>&1 > "$EC2_METADATA_MOCK_LOG_FILE_PATH"
    rm -f "$EC2_METADATA_MOCK_PID_PATH"

    # Sleep a bit to give Flask a chance to stop
    sleep 1
  fi
}

@test "aws_get_instance_private_ip" {
  run aws_get_instance_private_ip
  assert_success
  assert_output "$meta_data_local_ipv4"
}

@test "aws_get_instance_public_ip" {
  run aws_get_instance_public_ip
  assert_success
  assert_output "$meta_data_public_ipv4"
}

@test "aws_get_instance_private_hostname" {
  run aws_get_instance_private_hostname
  assert_success
  assert_output "$meta_data_local_hostname"
}

@test "aws_get_instance_public_hostname" {
  run aws_get_instance_public_hostname
  assert_success
  assert_output "$meta_data_public_hostname"
}

@test "aws_get_instance_id" {
  run aws_get_instance_id
  assert_success
  assert_output "$meta_data_instance_id"
}

@test "aws_get_instance_region" {
  run aws_get_instance_region
  assert_success
  assert_output "$mock_region"
}

@test "aws_get_ec2_instance_availability_zone" {
  run aws_get_ec2_instance_availability_zone
  assert_success
  assert_output "$meta_data_placement__availability_zone"
}

