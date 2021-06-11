FROM ubuntu:16.04
MAINTAINER Gruntwork <info@gruntwork.io>

# Install basic dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y vim git python-pip jq sudo curl libffi-dev python3-dev && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    update-alternatives --config python && \
    curl https://bootstrap.pypa.io/pip/3.5/get-pip.py -o /tmp/get-pip.py && \
    python /tmp/get-pip.py

# Install Bats
RUN git clone https://github.com/bats-core/bats-core.git /tmp/bats-core && \
    /tmp/bats-core/install.sh /usr/local && \
    rm -r /tmp/bats-core

# Upgrade pip
RUN pip install -U pip

# Install AWS CLI
RUN pip install awscli --upgrade --user

# Install moto: https://github.com/spulec/moto
RUN pip install flask moto moto[server] networkx==2.2

# Install tools we'll need to create a mock EC2 metadata server
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y net-tools iptables

# Copy mock AWS CLI into the PATH
COPY ./.circleci/aws-local.sh /usr/local/bin/aws

# These have been added to resolve some encoding error issues with the tests. These were introduced during the upgrade to Python 3.6,
# which is known to have some sensitivity around locale issues. These variables should correct that, per examples like this SO thread:
# https://stackoverflow.com/questions/51026315/how-to-solve-unicodedecodeerror-in-python-3-6/51027262#51027262.
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
