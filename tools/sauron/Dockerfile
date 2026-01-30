FROM alpine:3.19

ARG TERRAFORM_VERSION=1.6.6
ARG HELM_VERSION=v3.14.4
ENV RANCHER_CLI_VERSION=v2.13.1

RUN apk add --no-cache \
    bash curl unzip ca-certificates wget tar \
    aws-cli kubectl \
 && update-ca-certificates

# terraform
RUN curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    -o /tmp/terraform.zip \
 && unzip /tmp/terraform.zip -d /usr/local/bin \
 && rm /tmp/terraform.zip

# helm
RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
  | tar xz -C /tmp \
 && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
 && chmod +x /usr/local/bin/helm \
 && rm -rf /tmp/linux-amd64

# rancher cli
RUN wget -qO- "https://github.com/rancher/cli/releases/download/${RANCHER_CLI_VERSION}/rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz" \
  | tar xz -C /tmp \
 && mv "/tmp/rancher-${RANCHER_CLI_VERSION}/rancher" /usr/local/bin/rancher \
 && chmod +x /usr/local/bin/rancher \
 && rm -rf /tmp/*

# your helper scripts (optional)
ADD scripts /tmp/scripts
RUN chmod -R +x /tmp/scripts \
 && mv /tmp/scripts/* /usr/local/bin/ \
 && rm -rf /tmp/scripts

WORKDIR /opt
ENTRYPOINT ["/bin/sh"]
