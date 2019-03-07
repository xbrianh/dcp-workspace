# This is the build image for the DSS, intended for use with the allspark GitLab server
# It may be built and uploaded with the commands:
#   `docker login
#   `docker build -f workspace.Dockerfile -t xbrianh/workspace .`
#   `docker push xbrianh/workspace`
#
# Please see Docker startup guide for additional info:
#   https://docs.docker.com/get-started/ 

FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update --quiet \
    && apt-get install --assume-yes --no-install-recommends \
        ca-certificates \
        build-essential \
        default-jre \
        gettext \
        git \
		bash-completion \
        httpie \
        jq \
        make \
        moreutils \
        python3-pip \
        python3.6-dev \
        unzip \
        wget \
        zlib1g-dev \
		screen \
		gnupg \
		curl \
		python3-jedi \
		vim \
		vim-python-jedi \
		vim-addon-manager \
		sudo

# Install the Google Cloud SDK
RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-bionic main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN apt-get update --quiet && apt-get install --assume-yes --no-install-recommends google-cloud-sdk

# Configure some python components
RUN python3 -m pip install --upgrade pip setuptools
RUN python3 -m pip install --upgrade awscli virtualenv==16.0.0

# Create a user
RUN groupadd -g 999 dcp && useradd --home /home/dcp -m -s /bin/bash -g dcp -G sudo dcp
RUN bash -c "echo 'dcp ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
USER dcp
WORKDIR /home/dcp
ENV PATH /home/dcp/bin:${PATH}
RUN mkdir -p /home/dcp/bin

# Configure vim
RUN git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
RUN vim-addons install python-jedi

# Grab the ES version for DSS testing
ENV ES_VERSION 5.4.2
ENV DSS_TEST_ES_PATH=/home/dcp/elasticsearch-${ES_VERSION}/bin/elasticsearch
RUN wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ES_VERSION}.tar.gz \
    && tar -xzf elasticsearch-${ES_VERSION}.tar.gz -C /home/dcp

# Grab Terraform
RUN wget https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip \
    && unzip terraform_0.11.11_linux_amd64.zip -d /home/dcp/bin

# Address locale problem, see "Python 3 Surrogate Handling":
# http://click.pocoo.org/5/python3/
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
