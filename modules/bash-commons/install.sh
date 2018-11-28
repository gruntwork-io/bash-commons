#!/usr/bin/env bash
# This script is used by the Gruntwork Installer to install the bash-commons library.

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BASH_COMMONS_SRC_DIR="$SCRIPT_DIR/src"

# shellcheck source=./modules/bash-commons/src/log.sh
source "$BASH_COMMONS_SRC_DIR/log.sh"
# shellcheck source=./modules/bash-commons/src/assert.sh
source "$BASH_COMMONS_SRC_DIR/assert.sh"
# shellcheck source=./modules/bash-commons/src/os.sh
source "$BASH_COMMONS_SRC_DIR/os.sh"

readonly DEFAULT_INSTALL_DIR="/opt/gruntwork/bash-commons"
readonly DEFAULT_USER_NAME="$(os_get_current_users_name)"
readonly DEFAULT_USER_GROUP_NAME="$(os_get_current_users_group)"

function print_usage {
  echo
  echo "Usage: install.sh [options]"
  echo
  echo "This script is used by the Gruntwork Installter to install the bash-commons library."
  echo
  echo "Options:"
  echo
  echo -e "  --dir\t\tInstall the bash-commons library into this folder. Default: $DEFAULT_INSTALL_DIR"
  echo -e "  --owner\tMake this user the owner of the folder in --dir. Default: $DEFAULT_USER_NAME."
  echo -e "  --group\tMake this group the owner of the folder in --dir. Default: $DEFAULT_USER_GROUP_NAME."
  echo -e "  --help\tShow this help text and exit."
  echo
  echo "Example:"
  echo
  echo "  gruntwork-install --repo https://github.com/gruntwork-io/bash-commons --module-name bash-commons --tag v0.0.1 --module-param dir=/opt/gruntwork/bash-commons"
}

function install {
  local install_dir="$DEFAULT_INSTALL_DIR"
  local install_dir_owner="$DEFAULT_USER_NAME"
  local install_dir_group="$DEFAULT_USER_GROUP_NAME"

  while [[ $# -gt 0 ]]; do
    local key="$1"

    case "$key" in
      --dir)
        assert_not_empty "$key" "$2"
        install_dir="$2"
        shift
        ;;
      --owner)
        assert_not_empty "$key" "$2"
        install_dir_owner="$2"
        shift
        ;;
      --group)
        assert_not_empty "$key" "$2"
        install_dir_group="$2"
        shift
        ;;
      --help)
        print_usage
        exit
        ;;
      *)
        log_error "Unrecognized argument: $key"
        print_usage
        exit 1
        ;;
    esac

    shift
  done

  log_info "Starting install of bash-commons..."

  sudo mkdir -p "$install_dir"
  sudo cp -R "$BASH_COMMONS_SRC_DIR/." "$install_dir"
  sudo chown -R "$install_dir_owner:$install_dir_group" "$install_dir"

  log_info "Successfully installed bash-commons!"
}

install "$@"