#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/../modules/bash-commons/src/aws-wrapper.sh"
load "test-helper"
load "aws-helper"

@test "aws_wrapper_get_asg_name ASG tag only" {
  local readonly asg_name="foo"
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly tags=$(cat <<END_HEREDOC
{
   "Tags": [
     {
       "ResourceType": "instance",
       "ResourceId": "i-1234567890abcdef0",
       "Value": "asg_name",
       "Key": "aws:autoscaling:groupName"
     }
   ]
 }
END_HEREDOC
)

  load_aws_mock "$tags" "" ""

  local out
  out=$(aws_wrapper_get_asg_name "$max_retries" "$sleep_between_retries")

  assert_success
  assert_equal "foo" "$asg_name"
}

@test "aws_wrapper_get_asg_name ASG tag and other tags" {
  local readonly asg_name="foo"
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly tags=$(cat <<END_HEREDOC
{
   "Tags": [
     {
       "ResourceType": "instance",
       "ResourceId": "i-1234567890abcdef0",
       "Value": "bar",
       "Key": "foo"
     },
     {
       "ResourceType": "instance",
       "ResourceId": "i-1234567890abcdef0",
       "Value": "asg_name",
       "Key": "aws:autoscaling:groupName"
     },
     {
       "ResourceType": "instance",
       "ResourceId": "i-1234567890abcdef0",
       "Value": "blah",
       "Key": "baz"
     }
   ]
 }
END_HEREDOC
)

  load_aws_mock "$tags" "" ""

  local out
  out=$(aws_wrapper_get_asg_name "$max_retries" "$sleep_between_retries")

  assert_success
  assert_equal "foo" "$asg_name"
}

@test "aws_wrapper_get_asg_name no tags" {
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly tags=$(cat <<END_HEREDOC
{
   "Tags": []
 }
END_HEREDOC
)

  load_aws_mock "$tags" "" ""

  run aws_wrapper_get_asg_name "$max_retries" "$sleep_between_retries"

  assert_failure
}

@test "aws_wrapper_get_asg_name no ASG tags" {
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly tags=$(cat <<END_HEREDOC
{
   "Tags": [
     {
       "ResourceType": "instance",
       "ResourceId": "i-1234567890abcdef0",
       "Value": "bar",
       "Key": "foo"
     }
   ]
 }
END_HEREDOC
)
  load_aws_mock "$tags" "" ""

  run aws_wrapper_get_asg_name "$max_retries" "$sleep_between_retries"

  assert_failure
}

@test "aws_wrapper_get_instance_tag no tags" {
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly tags=$(cat <<END_HEREDOC
{
   "Tags": []
 }
END_HEREDOC
)

  load_aws_mock "$tags" "" ""

  run aws_wrapper_get_instance_tag "i-1234567890abcdef0" "us-east-1" "foo" "$max_retries" "$sleep_between_retries"

  assert_failure
}

@test "aws_wrapper_get_instance_tag no matching tag" {
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly tags=$(cat <<END_HEREDOC
{
   "Tags": [
     {
       "ResourceType": "instance",
       "ResourceId": "i-1234567890abcdef0",
       "Value": "blah",
       "Key": "baz"
     }
   ]
 }
END_HEREDOC
)

  load_aws_mock "$tags" "" ""

  run aws_wrapper_get_instance_tag "i-1234567890abcdef0" "us-east-1" "foo" "$max_retries" "$sleep_between_retries"

  assert_failure
}

@test "aws_wrapper_get_instance_tag matching tag" {
  local readonly tag_key="foo"
  local readonly tag_value="bar"
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly tags=$(cat <<END_HEREDOC
{
   "Tags": [
     {
       "ResourceType": "instance",
       "ResourceId": "i-1234567890abcdef0",
       "Value": "$tag_value",
       "Key": "$tag_key"
     }
   ]
 }
END_HEREDOC
)

  load_aws_mock "$tags" "" ""

  local out
  out=$(aws_wrapper_get_instance_tag "i-1234567890abcdef0" "us-east-1" "$tag_key" "$max_retries" "$sleep_between_retries")

  assert_success
  assert_equal "$tag_value" "$out"
}

@test "aws_wrapper_wait_for_instance_tags one tag" {
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly tags=$(cat <<END_HEREDOC
{
   "Tags": [
     {
       "ResourceType": "instance",
       "ResourceId": "i-1234567890abcdef0",
       "Value": "bar",
       "Key": "foo"
     }
   ]
 }
END_HEREDOC
)

  load_aws_mock "$tags" "" ""

  local out
  out=$(aws_wrapper_wait_for_instance_tags "i-1234567890abcdef0" "us-east-1" "$max_retries" "$sleep_between_retries")

  assert_success
  assert_equal "$tags" "$out"
}

@test "aws_wrapper_wait_for_instance_tags multiple tags" {
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly tags=$(cat <<END_HEREDOC
{
   "Tags": [
     {
       "ResourceType": "instance",
       "ResourceId": "i-1234567890abcdef0",
       "Value": "bar",
       "Key": "foo"
     },
     {
       "ResourceType": "instance",
       "ResourceId": "i-1234567890abcdef0",
       "Value": "blah",
       "Key": "baz"
     },
     {
       "ResourceType": "instance",
       "ResourceId": "i-1234567890abcdef0",
       "Value": "def",
       "Key": "abc"
     }
   ]
 }
END_HEREDOC
)

  load_aws_mock "$tags" "" ""

  local out
  out=$(aws_wrapper_wait_for_instance_tags "i-1234567890abcdef0" "us-east-1" "$max_retries" "$sleep_between_retries")

  assert_success
  assert_equal "$tags" "$out"
}

@test "aws_wrapper_wait_for_instance_tags no tags" {
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly tags=$(cat <<END_HEREDOC
{
   "Tags": []
 }
END_HEREDOC
)

  load_aws_mock "$tags" "" ""

  run aws_wrapper_wait_for_instance_tags "i-1234567890abcdef0" "us-east-1" "$max_retries" "$sleep_between_retries"
  assert_failure
}

@test "aws_wrapper_get_asg_size ASG exists" {
  local readonly size=4
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/asg-name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "asg-name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" ""

  local out
  out=$(aws_wrapper_get_asg_size "asg-name" "us-east-1" "$max_retries" "$sleep_between_retries")

  assert_success
  assert_equal "$size" "$out"
}

@test "aws_wrapper_get_asg_size ASG does not exist" {
  local readonly size=4
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0
  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": []
}
END_HEREDOC
)

  load_aws_mock "" "$asg" ""

  run aws_wrapper_get_asg_size "asg-name" "us-east-1" "$max_retries" "$sleep_between_retries"

  assert_failure
}

@test "aws_wrapper_wait_for_instances_in_asg ASG size 1" {
  local readonly size=1
  local readonly asg_name="asg-name"
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  local out
  out=$(aws_wrapper_wait_for_instances_in_asg "$asg_name" "us-east-1" "$max_retries" "$sleep_between_retries")

  assert_success
  assert_equal "$instances" "$out"
}

@test "aws_wrapper_wait_for_instances_in_asg ASG size 3" {
  local readonly size=3
  local readonly asg_name="asg-name"
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef1",
          "PublicIpAddress": "55.66.77.881",
          "PrivateIpAddress": "11.22.33.441",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef2",
          "PublicIpAddress": "55.66.77.882",
          "PrivateIpAddress": "11.22.33.442",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  local out
  out=$(aws_wrapper_wait_for_instances_in_asg "$asg_name" "us-east-1" "$max_retries" "$sleep_between_retries")

  assert_success
  assert_equal "$instances" "$out"
}

@test "aws_wrapper_wait_for_instances_in_asg ASG size 2, 3 available" {
  local readonly size=2
  local readonly asg_name="asg-name"
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef1",
          "PublicIpAddress": "55.66.77.881",
          "PrivateIpAddress": "11.22.33.441",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef2",
          "PublicIpAddress": "55.66.77.882",
          "PrivateIpAddress": "11.22.33.442",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  local out
  out=$(aws_wrapper_wait_for_instances_in_asg "$asg_name" "us-east-1" "$max_retries" "$sleep_between_retries")

  assert_success
  assert_equal "$instances" "$out"
}

@test "aws_wrapper_wait_for_instances_in_asg ASG size 3, only 2 available" {
  local readonly size=3
  local readonly asg_name="asg-name"
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef1",
          "PublicIpAddress": "55.66.77.881",
          "PrivateIpAddress": "11.22.33.441",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  run aws_wrapper_wait_for_instances_in_asg "$asg_name" "us-east-1" "$max_retries" "$sleep_between_retries"

  assert_failure
}

@test "aws_wrapper_wait_for_instances_in_asg ASG size not available" {
  local readonly asg_name="asg-name"
  local reaodnly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": []
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef1",
          "PublicIpAddress": "55.66.77.881",
          "PrivateIpAddress": "11.22.33.441",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  run aws_wrapper_wait_for_instances_in_asg "$asg_name" "us-east-1" "$max_retries" "$sleep_between_retries"

  assert_failure
}

@test "aws_wrapper_get_ips_in_asg empty ASG" {
  local readonly asg_name="foo"
  local readonly size=0
  local readonly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": []
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  local out
  out=($(aws_wrapper_get_ips_in_asg "$asg_name" "us-east-1" "true" "$max_retries" "$sleep_between_retries"))

  local readonly expected=()

  assert_success
  assert_equal "$expected" "$out"
}

@test "aws_wrapper_get_ips_in_asg ASG size 1, public IPs" {
  local readonly asg_name="foo"
  local readonly size=1
  local readonly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  local out
  out=($(aws_wrapper_get_ips_in_asg "$asg_name" "us-east-1" "true" "$max_retries" "$sleep_between_retries"))

  local readonly expected=("55.66.77.88")

  assert_success
  assert_equal "$expected" "$out"
}

@test "aws_wrapper_get_ips_in_asg ASG size 3, public IPs" {
  local readonly asg_name="foo"
  local readonly size=3
  local readonly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    },
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef1",
          "PublicIpAddress": "55.66.77.881",
          "PrivateIpAddress": "11.22.33.441",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef2",
          "PublicIpAddress": "55.66.77.882",
          "PrivateIpAddress": "11.22.33.442",
          "PrivateDnsName": "ip-10-251-50-122.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-253.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  local out
  out=($(aws_wrapper_get_ips_in_asg "$asg_name" "us-east-1" "true" "$max_retries" "$sleep_between_retries"))

  local readonly expected=("55.66.77.88" "55.66.77.881" "55.66.77.882")

  assert_success
  assert_equal "$expected" "$out"
}

@test "aws_wrapper_get_ips_in_asg ASG size 3, private IPs" {
  local readonly asg_name="foo"
  local readonly size=3
  local readonly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    },
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef1",
          "PublicIpAddress": "55.66.77.881",
          "PrivateIpAddress": "11.22.33.441",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef2",
          "PublicIpAddress": "55.66.77.882",
          "PrivateIpAddress": "11.22.33.442",
          "PrivateDnsName": "ip-10-251-50-122.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-253.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  local out
  out=($(aws_wrapper_get_ips_in_asg "$asg_name" "us-east-1" "false" "$max_retries" "$sleep_between_retries"))

  local readonly expected=("11.22.33.44" "11.22.33.441" "11.22.33.442")

  assert_success
  assert_equal "$expected" "$out"
}

@test "aws_wrapper_get_hostnames_in_asg empty ASG" {
  local readonly asg_name="foo"
  local readonly size=0
  local readonly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": []
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  local out
  out=($(aws_wrapper_get_hostnames_in_asg "$asg_name" "us-east-1" "true" "$max_retries" "$sleep_between_retries"))

  local readonly expected=()

  assert_success
  assert_equal "$expected" "$out"
}

@test "aws_wrapper_get_hostnames_in_asg ASG size 1, public IPs" {
  local readonly asg_name="foo"
  local readonly size=1
  local readonly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  local out
  out=($(aws_wrapper_get_hostnames_in_asg "$asg_name" "us-east-1" "true" "$max_retries" "$sleep_between_retries"))

  local readonly expected=("ec2-203-0-113-25.compute-1.amazonaws.com")

  assert_success
  assert_equal "$expected" "$out"
}

@test "aws_wrapper_get_hostnames_in_asg ASG size 3, public IPs" {
  local readonly asg_name="foo"
  local readonly size=3
  local readonly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    },
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef1",
          "PublicIpAddress": "55.66.77.881",
          "PrivateIpAddress": "11.22.33.441",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef2",
          "PublicIpAddress": "55.66.77.882",
          "PrivateIpAddress": "11.22.33.442",
          "PrivateDnsName": "ip-10-251-50-122.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-253.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  local out
  out=($(aws_wrapper_get_hostnames_in_asg "$asg_name" "us-east-1" "true" "$max_retries" "$sleep_between_retries"))

  local readonly expected=("ec2-203-0-113-25.compute-1.amazonaws.com" "ec2-203-0-113-252.compute-1.amazonaws.com" "ec2-203-0-113-253.compute-1.amazonaws.com")

  assert_success
  assert_equal "$expected" "$out"
}

@test "aws_wrapper_get_hostnames_in_asg ASG size 3, private IPs" {
  local readonly asg_name="foo"
  local readonly size=3
  local readonly max_retries=1
  local readonly sleep_between_retries=0

  local readonly asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "us-west-2c"
            ]
        }
    ]
}
END_HEREDOC
)

  local readonly instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    },
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef1",
          "PublicIpAddress": "55.66.77.881",
          "PrivateIpAddress": "11.22.33.441",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef2",
          "PublicIpAddress": "55.66.77.882",
          "PrivateIpAddress": "11.22.33.442",
          "PrivateDnsName": "ip-10-251-50-122.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-253.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"

  local out
  out=($(aws_wrapper_get_hostnames_in_asg "$asg_name" "us-east-1" "false" "$max_retries" "$sleep_between_retries"))

  local readonly expected=("ip-10-251-50-12.ec2.internal" "ip-10-251-50-121.ec2.internal" "ip-10-251-50-122.ec2.internal")

  assert_success
  assert_equal "$expected" "$out"
}

@test "aws_wrapper_get_hostname public" {
  load_aws_mock "" "" ""

  local out
  out=$(aws_wrapper_get_hostname "true")

  assert_success
  assert_equal "ec2-203-0-113-25.compute-1.amazonaws.com" "$out"
}

@test "aws_wrapper_get_hostname private" {
  load_aws_mock "" "" ""

  local out
  out=$(aws_wrapper_get_hostname "false")

  assert_success
  assert_equal "ip-10-251-50-12.ec2.internal" "$out"
}

function setup_rally_point_by_instance {
  local -r asg_name="$1"
  local -r aws_region="$2"
  local -r size=3

  local -r asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "${aws_region}c"
            ]
        }
    ]
}
END_HEREDOC
)

  local -r instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    },
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef1",
          "PublicIpAddress": "55.66.77.881",
          "PrivateIpAddress": "11.22.33.441",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef2",
          "PublicIpAddress": "55.66.77.882",
          "PrivateIpAddress": "11.22.33.442",
          "PrivateDnsName": "ip-10-251-50-122.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-253.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"
}

@test "aws_wrapper_get_asg_rally_point by instance id, private" {
  local -r asg_name="foo"
  local -r aws_region="us-west-2"

  setup_rally_point_by_instance $asg_name $aws_region

  local out

  out=$(aws_wrapper_get_asg_rally_point $asg_name $aws_region)
  assert_success
  assert_equal "$out" "ip-10-251-50-12.ec2.internal"
}

@test "aws_wrapper_get_asg_rally_point by instance id, public" {
  local -r asg_name="foo"
  local -r aws_region="us-west-2"

  setup_rally_point_by_instance $asg_name $aws_region

  local out

  out=$(aws_wrapper_get_asg_rally_point $asg_name $aws_region true)
  assert_success
  assert_equal "$out" "ec2-203-0-113-25.compute-1.amazonaws.com"
}

function setup_rally_point_by_launch_time {
  local -r asg_name="$1"
  local -r aws_region="$2"
  local -r size=3

  local -r asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "${aws_region}c"
            ]
        }
    ]
}
END_HEREDOC
)

local -r instances=$(cat <<END_HEREDOC
{
  "Reservations": [
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef0",
          "PublicIpAddress": "55.66.77.88",
          "PrivateIpAddress": "11.22.33.44",
          "PrivateDnsName": "ip-10-251-50-12.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-25.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    },
    {
      "Instances": [
        {
          "LaunchTime": "2013-08-19T20:53:25.584Z",
          "InstanceId": "i-1234567890abcdef1",
          "PublicIpAddress": "55.66.77.881",
          "PrivateIpAddress": "11.22.33.441",
          "PrivateDnsName": "ip-10-251-50-121.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-252.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        },
        {
          "LaunchTime": "2013-08-19T20:53:24.584Z",
          "InstanceId": "i-1234567890abcdef2",
          "PublicIpAddress": "55.66.77.882",
          "PrivateIpAddress": "11.22.33.442",
          "PrivateDnsName": "ip-10-251-50-122.ec2.internal",
          "PublicDnsName": "ec2-203-0-113-253.compute-1.amazonaws.com",
          "Tags": [
            {
              "Value": "$asg_name",
              "Key": "aws:autoscaling:groupName"
            }
          ]
        }
      ]
    }
  ]
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"
}

@test "aws_wrapper_get_asg_rally_point by launch time, private" {
  local -r asg_name="foo"
  local -r aws_region="us-west-2"

  setup_rally_point_by_launch_time $asg_name $aws_region

  local out

  out=$(aws_wrapper_get_asg_rally_point $asg_name $aws_region)
  assert_success
  assert_equal "$out" "ip-10-251-50-122.ec2.internal"
}

@test "aws_wrapper_get_asg_rally_point by launch time, public" {
  local -r asg_name="foo"
  local -r aws_region="us-west-2"

  setup_rally_point_by_launch_time $asg_name $aws_region

  local out

  out=$(aws_wrapper_get_asg_rally_point $asg_name $aws_region true)
  assert_success
  assert_equal "$out" "ec2-203-0-113-253.compute-1.amazonaws.com"
}

function setup_rally_point_empty {
  local -r asg_name="$1"
  local -r aws_region="$2"
  local -r size=3

  local -r asg=$(cat <<END_HEREDOC
{
    "AutoScalingGroups": [
        {
            "AutoScalingGroupARN": "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:930d940e-891e-4781-a11a-7b0acd480f03:autoScalingGroupName/$asg_name",
            "DesiredCapacity": $size,
            "AutoScalingGroupName": "$asg_name",
            "MinSize": 0,
            "MaxSize": 10,
            "LaunchConfigurationName": "my-launch-config",
            "CreatedTime": "2013-08-19T20:53:25.584Z",
            "AvailabilityZones": [
                "${aws_region}c"
            ]
        }
    ]
}
END_HEREDOC
)

local -r instances=$(cat <<END_HEREDOC
{
  "Reservations": []
}
END_HEREDOC
)

  load_aws_mock "" "$asg" "$instances"
}

@test "aws_wrapper_get_asg_rally_point empty asg, private" {
  local -r asg_name="foo"
  local -r aws_region="us-west-2"
  local -r use_public_hostname="false"
  local -r retries=5
  local -r sleep_between_retries=2

  setup_rally_point_empty $asg_name $aws_region

  run aws_wrapper_get_asg_rally_point $asg_name $aws_region $use_public_hostname $retries $sleep_between_retries
  assert_failure
}

@test "aws_wrapper_get_asg_rally_point empty asg, public" {
  local -r asg_name="foo"
  local -r aws_region="us-west-2"
  local -r use_public_hostname="true"
  local -r retries=5
  local -r sleep_between_retries=2

  setup_rally_point_empty $asg_name $aws_region

  run aws_wrapper_get_asg_rally_point $asg_name $aws_region $use_public_hostname $retries $sleep_between_retries
  assert_failure
}
