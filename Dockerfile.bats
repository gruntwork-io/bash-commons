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

# Install AWS CLI
RUN pip install awscli --upgrade --user

# Install moto: https://github.com/spulec/moto
RUN pip install flask moto moto[server]

# Install tools we'll need to create a mock EC2 metadata server
RUN apt-get install -y net-tools iptables

# Copy mock AWS CLI into the PATH
COPY ./.circleci/aws-local.sh /usr/local/bin/aws
