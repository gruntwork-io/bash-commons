FROM ubuntu:20.04
MAINTAINER Gruntwork <info@gruntwork.io>

# Install basic dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git vim python3-pip jq sudo curl libffi-dev python3-dev

# Install Bats
RUN git clone https://github.com/bats-core/bats-core.git /tmp/bats-core && \
    /tmp/bats-core/install.sh /usr/local && \
    rm -r /tmp/bats-core

# Upgrade pip
RUN pip3 install -U pip

# Install AWS CLI
RUN pip3 install awscli --upgrade --user

# Install moto: https://github.com/spulec/moto
# Lock cfn-lint and pysistent to last known working versions
RUN pip3 install flask moto moto[server] cfn-lint==0.35.1 pyrsistent==0.16.0

# Install tools we'll need to create a mock EC2 metadata server
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y net-tools iptables

# Copy mock AWS CLI into the PATH
COPY ./.circleci/aws-local.sh /usr/local/bin/aws

# These have been added to resolve some encoding error issues with the tests. These were introduced during the upgrade to Python 3.6,
# which is known to have some sensitivity around locale issues. These variables should correct that, per examples like this SO thread:
# https://stackoverflow.com/questions/51026315/how-to-solve-unicodedecodeerror-in-python-3-6/51027262#51027262.
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
