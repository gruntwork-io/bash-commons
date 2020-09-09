#!/bin/bash

set -e

# ---------------------------------------------------------------------------------------------------------------------
# Dynamic Ubuntu Wait script
#
# This script attempts a nicer solution to getting around Ubuntu's automatic updates
# preventing package installation.
#
# Automated tools such as packer occasionally run into issues when they try to
# call apt but Ubuntu's internal automatic updater is still running.
#
# Most of the time, adding a 'sleep X' call does the trick, but if you make the sleep too long
# then you slow down all of your builds. If you make the sleep too short you will still occasionally
# have issues.
#
# With this script, we poll both locks until they are released thereby having the minimum possible wait
# while still waiting long enough for the locks to be released.
#
# See https://groups.google.com/d/msg/packer-tool/NTvZP56DRqw/snr8PyoDBwAJ
# and https://github.com/boxcutter/ubuntu/issues/86",
# ---------------------------------------------------------------------------------------------------------------------

echo "Dynamically waiting for ubuntu's automatic update mechanism to let go of locks..."

sleep 15 # In case this script is the very first command being run, we wait a bit to give unattended upgrades a chance to start.

while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 1; echo 'waiting'; done
while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; echo 'still waiting'; done

echo "All locks should have been released..."