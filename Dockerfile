FROM docker:18.09 as docker

FROM python:3-slim-stretch

# apt-get
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        vim \
        git \
        jq \
        dnsutils \
        telnet \
        traceroute \
        curl \
        gettext-base \
        gawk \
        sed \
        tar \
        unzip \
        socat \
        rsync \
        net-tools \
        ssh \
        gnupg

# pip3
RUN pip3 --no-cache-dir install \
    awscli \
    yq

ARG HEPTIO_URL=https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
ARG HELM_URL=https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz
ARG HELM_FOLDER=linux-amd64
ARG HELM_DIFF_URL=https://github.com/databus23/helm-diff
ARG HELM_DIFF_VERSION="2.11.0+3"
ARG SOPS_URL=https://github.com/mozilla/sops/releases/download/3.2.0/sops-3.2.0.linux
ARG GIT_AUTO_COMPLETION_URL=https://github.com/git/git/blob/master/contrib/completion/git-completion.bash

# curl aws-iam-authenticator
ENV BIN_PATH=/usr/local/bin \
    EDITOR=vim \
    KUBECONFIG=/root/.kube/kubeconfig.yaml

WORKDIR /srv

COPY build/scripts scripts
COPY build/kubeconfig.yaml /root/.kube/

# pre commands

# apt-get kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | apt-key add - \
    && touch /etc/apt/sources.list.d/kubernetes.list \
    && echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" \
        | tee -a /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        kubectl \
    && ln -s /usr/bin/kubectl /usr/bin/ku

RUN curl -L $HEPTIO_URL \
        -o $BIN_PATH/aws-iam-authenticator \
    && chmod +x $BIN_PATH/aws-iam-authenticator \
    && ln -s $BIN_PATH/aws-iam-authenticator $BIN_PATH/heptio-authenticator-aws

# sops
RUN curl -L $SOPS_URL \
        -o $BIN_PATH/sops \
    && chmod +x $BIN_PATH/sops

# curl helm
RUN curl -L $HELM_URL \
        -o helm.tar.gz \
    && tar -xvf helm.tar.gz \
    && mv $HELM_FOLDER/helm $BIN_PATH \
    && mkdir -p $HOME/.helm/plugins \
    && helm plugin install $HELM_DIFF_URL --version $HELM_DIFF_VERSION \
    && helm init --client-only \
    && rm -rf helm.tar.gz $HELM_FOLDER \
    && helm repo remove stable local

# post commands
RUN echo "alias ll='ls -lrt'" >> $HOME/.bashrc \
    && echo "source <(kubectl completion bash)" >> $HOME/.bashrc \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

COPY --from=docker /usr/local/bin/docker /usr/local/bin/

ENTRYPOINT ["/srv/scripts/entrypoint.sh"]
