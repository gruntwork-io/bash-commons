#!/usr/bin/env bash
# A wrapper script for the AWS CLI that redirects all calls to localhost:5000 so that they go to moto instead of the
# real AWS servers. This script should be installed in the PATH so it gets called instead of the real AWS CLI, and this
# script will, in turn, call the real AWS CLI.

set -e

# Set mock values so the AWS CLI doesn't complain
export AWS_ACCESS_KEY_ID="mock-for-testing"
export AWS_SECRET_ACCESS_KEY="mock-for-testing"
export AWS_DEFAULT_REGION="us-east-1"

# We assume that the AWS CLI has been installed by pip into this path
readonly REAL_AWS_CLI="$HOME/.local/bin/aws"

"$REAL_AWS_CLI" --endpoint-url=http://localhost:5000 "$@"