FROM hashicorp/terraform:1.14


ENV RANCHER_CLI_VERSION=v2.13.1

RUN apk add --no-cache \
    aws-cli \
    kubectl \
    bash \
    ca-certificates \
    wget \
    tar \
 && update-ca-certificates

RUN wget -qO- https://github.com/rancher/cli/releases/download/${RANCHER_CLI_VERSION}/rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz \
  | tar xz -C /tmp \
 && mv /tmp/rancher-${RANCHER_CLI_VERSION}/rancher /usr/local/bin/rancher \
 && chmod +x /usr/local/bin/rancher \
 && rm -rf /tmp/*

ADD scripts /tmp/scripts
RUN chmod -R +x /tmp/scripts \
 && mv /tmp/scripts/* /usr/local/bin/ \
 && rm -rf /tmp/scripts

ENTRYPOINT ["/bin/sh"]