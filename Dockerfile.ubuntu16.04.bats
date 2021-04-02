FROM ubuntu:16.04
MAINTAINER Gruntwork <info@gruntwork.io>

# Install basic dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y vim python-pip jq sudo curl

# Install Bats
RUN apt-get install -y software-properties-common && \
    add-apt-repository ppa:duggan/bats && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y bats

# Upgrade pip
RUN sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    sudo update-alternatives --config python && \
    curl https://bootstrap.pypa.io/pip/3.5/get-pip.py -o /tmp/get-pip.py && \
    python /tmp/get-pip.py && \
    pip install -U pip

# Install AWS CLI
RUN pip install awscli --upgrade --user

# Install moto: https://github.com/spulec/moto
RUN sudo apt install libffi-dev python3-dev -y && \
    pip install flask moto moto[server] networkx==2.2

# Install tools we'll need to create a mock EC2 metadata server
RUN apt-get install -y net-tools iptables

# Copy mock AWS CLI into the PATH
COPY ./.circleci/aws-local.sh /usr/local/bin/aws
