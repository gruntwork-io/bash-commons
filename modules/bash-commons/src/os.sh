#!/bin/bash

set -e

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log.sh"

# Return the available memory on the current OS in MB
function os_get_available_memory_mb {
  free -m | awk 'NR==2{print $2}'
}

# Returns true (0) if this is an Amazon Linux server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_amazon_linux {
  local readonly version="$1"
  grep -q "Amazon Linux * $version" /etc/*release
}

# Returns true (0) if this is an Ubuntu server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_ubuntu {
  local readonly version="$1"
  grep -q "Ubuntu $version" /etc/*release
}

# Returns true (0) if this is a CentOS server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_centos {
  local readonly version="$1"
  grep -q "CentOS Linux release $version" /etc/*release
}

# Returns true (0) if this is a RedHat server at the given version or false (1) otherwise. The version number
# can use regex. If you don't care about the version, leave it unspecified.
function os_is_redhat {
  local readonly version="$1"
  grep -q "Red Hat Enterprise Linux Server release $version" /etc/*release
}


# Returns true (0) if this is an OS X server or false (1) otherwise.
function os_is_darwin {
  [[ $(uname -s) == "Darwin" ]]
}

# Validate that the given file has the given checksum of the given checksum type, where type is one of "md5" or
# "sha256".
function os_validate_checksum {
  local readonly filepath="$1"
  local readonly checksum="$2"
  local readonly checksum_type="$3"

  case "$checksum_type" in
    sha256)
      log_info "Validating sha256 checksum of $filepath is $checksum"
      echo "$checksum $filepath" | sha256sum -c
      ;;
    md5)
      log_info "Validating md5 checksum of $filepath is $checksum"
      echo "$checksum $filepath" | md5sum -c
      ;;
    *)
      log_error "Unsupported checksum type: $checksum_type."
      exit 1
  esac
}

# Returns true (0) if this the given command/app is installed and on the PATH or false (1) otherwise.
function os_command_is_installed {
  local readonly name="$1"
  command -v "$name" > /dev/null
}

# Get the username of the current OS user
function os_get_current_users_name {
  id -u -n
}

# Get the name of the primary group for the current OS user
function os_get_current_users_group {
  id -g -n
}

# Returns true (0) if the current user is root or sudo and false (1) otherwise.
function os_user_is_root_or_sudo {
  [[ "$EUID" == 0 ]]
}
