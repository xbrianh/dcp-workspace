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
    zip \
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
    ssh \
    sudo \
    groff \
    less

# Install the Google Cloud SDK
RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-bionic main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN apt-get update --quiet && apt-get install --assume-yes --no-install-recommends google-cloud-sdk

# Install kubectl, helm, and tiller (needed for allspark EKS cluster management)
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update --quiet && apt-get install --assume-yes --no-install-recommends kubectl
RUN curl -o /usr/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/linux/amd64/aws-iam-authenticator \
    && chmod +x /usr/bin/aws-iam-authenticator \
    && cp /usr/bin/aws-iam-authenticator /usr/bin/heptio-authenticator-aws
RUN wget https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz \
    && tar -zxvf helm-v2.11.0-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/bin/helm && chmod +x /usr/bin/helm \
    && mv linux-amd64/tiller /usr/bin/tiller && chmod +x /usr/bin/tiller

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

# Configure git
RUN git clone https://github.com/awslabs/git-secrets.git \
    && (cd git-secrets && sudo make install) \
    && git secrets --register-aws --global \
    && git secrets --install ~/.git-templates/git-secrets \
    && git secrets --add --global 'BEGINPRIVATEKEY.*ENDPRIVATEKEY' # google private key pattern \
    && git config --global init.templateDir ~/.git-templates/git-secrets
RUN wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash \
    && mv git-completion.bash ~/.git-completion.bash \
    && echo "source ~/.git-completion.bash" >> ~/.bashrc

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

# Copy public key into container as an authorized key
RUN mkdir /home/dcp/.ssh
ADD key.pub /home/dcp/.ssh/authorized_keys

# Install mosh
RUN sudo apt-get update --quiet && sudo apt-get install --assume-yes locales mosh
RUN sudo locale-gen en_US.UTF-8

# Install dotfiles
ADD bash_functions /home/dcp/.bash_functions
ADD bashrc /home/dcp/.bashrc
ADD vimrc /home/dcp/.vimrc

# Make sure the user ownes everything
RUN ["sudo", "chown", "-R", "dcp:dcp", "/home/dcp"]

# disable login messages so scp works
RUN sudo chmod -x /etc/update-motd.d/*

# Expose ssh port
EXPOSE 22

# Expose mosh ports
EXPOSE 60000-61000

# Add the entrypoint script, but don't assign it
ADD entrypoint.sh /home/dcp/bin/entrypoint.sh
