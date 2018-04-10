FROM ubuntu:16.04
MAINTAINER Gruntwork <info@gruntwork.io>

# Install Bats
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:duggan/bats && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y bats

# Install AWS CLI and jq
RUN apt-get install -y python-pip jq && \
    pip install awscli --upgrade --user