FROM ubuntu:18.04
MAINTAINER Gruntwork <info@gruntwork.io>

# Install basic dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y vim python-pip jq sudo curl libffi-dev python3-dev

# Install Bats
RUN apt-get install -y software-properties-common && \
    add-apt-repository ppa:duggan/bats && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y bats

# Install AWS CLI
RUN apt install python3-distutils python3-apt -y && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    update-alternatives --config python && \
    curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py && \
    python /tmp/get-pip.py && \
    pip install awscli --upgrade --user

# Install moto: https://github.com/spulec/moto
# Lock cfn-lint and pysistent to last known working versions
RUN pip install flask moto moto[server] cfn-lint==0.35.1 pyrsistent==0.16.0

# Install tools we'll need to create a mock EC2 metadata server
RUN apt-get install -y net-tools iptables

# Copy mock AWS CLI into the PATH
COPY ./.circleci/aws-local.sh /usr/local/bin/aws

# These have been added to resolve some encoding error issues with the tests
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8