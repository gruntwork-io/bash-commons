#!/usr/bin/env bash
#
# A collection of Bash functions that implement helpful operations required by Java. Because Kafka and Confluent Tools
# are written in Java, these functions are especially useful for installing key store and trust store files.
#

# shellcheck source=./modules/bash-commons/src/assert.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"
# shellcheck source=./modules/bash-commons/src/log.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/log.sh"

# If the key store file specified by $src exists, copy it to $dst
# - Note that we *move* Key Store files, while we *copy* Trust Store files. That's because Key Stores are secrets but
#   Trust Stores are not.
function java_install_key_store_files {
  local -r src="$1"
  local -r dst="$2"
  local -r description="$3"

  assert_uid_is_root_or_sudo

  if [[ ! -z "$src" ]]; then
    log_info "Moving files from $src/ to $dst/ and setting read-only permissions"
    mkdir -p "$dst"
    mv $src/* "$dst/"
    chmod -R 0500 "$dst"
  elif [[ "$src" == "" ]]; then
    log_warn "No $description folder was specified. Will not attempt to install."
  else
    log_info "No $description folder exists at $src. Will not attempt to mv to $dst"
  fi
}

# If the trust store file specified by $src exists, cp it to $dst
# - Note that we *copy* Trust Store files, while we *move* Key Store files. That's because Key Stores are secrets but
#   Trust Stores are not.
function java_install_trust_store_files {
  local -r src="$1"
  local -r dst="$2"
  local -r description="$3"

  assert_uid_is_root_or_sudo
  
  if [[ -d "$src" ]]; then
    log_info "Copying files from $src/ to $dst/ and setting read-only permissions"
    mkdir -p "$dst"
    cp -r "$src/." "$dst/"
    chmod -R 0500 "$dst"
  elif [[ "$src" == "" ]]; then
    log_warn "No $description was specified. Will not attempt to install."
  else
    log_info "No $description folder exists at $src. Will not attempt to cp to $dst"
  fi
}
