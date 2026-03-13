![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4)
![Kubernetes](https://img.shields.io/badge/Kubernetes-RKE2-blue)
![Platform](https://img.shields.io/badge/Platform-Rancher-green)
![Cloud](https://img.shields.io/badge/Cloud-AWS-orange)

# terraform-aws-platform

## Overview

This repository demonstrates how to build a Rancher-managed Kubernetes platform on AWS using Terraform.

The platform automatically provisions:

- AWS infrastructure (VPC, security groups, EC2 instances)
- a bootstrap Kubernetes cluster using k3s
- Rancher installed via Helm
- TLS certificates via cert-manager and Let's Encrypt
- a downstream RKE2 Kubernetes cluster
- control plane and worker nodes managed by Rancher machine pools

The goal is to demonstrate a reproducible platform engineering workflow using Infrastructure as Code.


## Architecture

This project uses a staged Terraform design because the Kubernetes API, Helm resources, Rancher bootstrap, and downstream cluster provisioning depend on each other in sequence.

```text
                         +----------------------------------+
                         |             AWS                  |
                         |----------------------------------|
                         | VPC / Subnet / Security Group    |
                         | EC2 for k3s management node      |
                         | EC2 for downstream RKE2 nodes    |
                         +----------------+-----------------+
                                          |
                                          v
                         +----------------------------------+
                         |     k3s Bootstrap Cluster        |
                         |----------------------------------|
                         | cert-manager                     |
                         | ClusterIssuer (Let's Encrypt)    |
                         | Rancher installed with Helm      |
                         +----------------+-----------------+
                                          |
                                          v
                         +----------------------------------+
                         |            Rancher               |
                         |----------------------------------|
                         | Cloud credential / node templates|
                         | Machine provisioning on AWS      |
                         | Cluster management API/UI        |
                         +----------------+-----------------+
                                          |
                                          v
                         +----------------------------------+
                         |     Downstream RKE2 Cluster      |
                         |----------------------------------|
                         | Control plane nodes              |
                         | Worker nodes                     |
                         | Managed from Rancher             |
                         +----------------------------------+
```
## Resulting Rancher Cluster

Example of the Rancher-managed downstream RKE2 cluster created by this project.

![Rancher Cluster Dashboard](docs/rancher-cluster-dashboard.png)

## Provisioning Workflow

1. Terraform provisions AWS networking and an EC2 instance for the bootstrap management node.
2. The bootstrap node installs k3s and exposes a kubeconfig for follow-up Terraform stages.
3. Terraform installs cert-manager into the k3s cluster.
4. Terraform creates a Let's Encrypt `ClusterIssuer` for Rancher ingress TLS.
5. Terraform installs Rancher on the k3s cluster via Helm.
6. Terraform connects to the Rancher API, configures machine provisioning, and requests a downstream cluster.
7. Rancher provisions EC2 instances and installs RKE2 agents and servers to form the downstream Kubernetes cluster.

## Repository Layout

```text
terraform/
├── aws-root/                          # AWS network + k3s bootstrap node
├── platform/platform-cert-manager-root/ # cert-manager installation
├── platform/platform-issuer-root/       # Let's Encrypt ClusterIssuer
├── rancher/rancher-server-root/         # Rancher installation and bootstrap
├── rancher/downstream-rke2-root/        # Downstream RKE2 cluster provisioning
└── modules/                             # Reusable Terraform modules
```

## Prerequisites

- Terraform `>= 1.6`
- AWS account and credentials with permission to create VPC, security groups, and EC2 resources
- An existing EC2 key pair and access to its private key for bootstrap SSH
- `kubectl`, `helm`, and `scp` available on the operator machine
- A public DNS name for Rancher, or a dynamic hostname such as `nip.io`
- Port `80` reachable for Let's Encrypt HTTP-01 validation when using automatic TLS

## AWS Authentication

Terraform AWS resources use the standard AWS credential chain. The simplest local option is environment variables:

```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="eu-west-3"
```

If you use temporary credentials, also export:

```bash
export AWS_SESSION_TOKEN="YOUR_SESSION_TOKEN"
```

You can also use `AWS_PROFILE` with `~/.aws/credentials`.

For downstream cluster provisioning, Rancher also needs AWS credentials to create EC2 machines. In `terraform/rancher/downstream-rke2-root`, choose one of these approaches:
- set `cloud_credential_id` to reuse an existing Rancher cloud credential
- or set `access_key` and `secret_key` in `env/dev.tfvars`

## How To Deploy

Use the example tfvars files in each Terraform root as the starting point.

### 1. Provision AWS and bootstrap k3s

```bash
cd terraform/aws-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

This stage creates the AWS network, the management EC2 instance, installs k3s, and writes the kubeconfig used by the next stages.

### 2. Install cert-manager

```bash
cd terraform/platform/platform-cert-manager-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

### 3. Create the Let's Encrypt issuer

```bash
cd terraform/platform/platform-issuer-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

### 4. Install Rancher

```bash
cd terraform/rancher/rancher-server-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

### 5. Provision the downstream RKE2 cluster

```bash
cd terraform/rancher/downstream-rke2-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

The result is a Rancher-managed downstream RKE2 cluster with configurable control plane and worker node counts.

## How To Destroy The Infrastructure

Destroy in reverse order to avoid dependency and remote-state issues.

```bash
cd terraform/rancher/downstream-rke2-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/rancher/rancher-server-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/platform/platform-issuer-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/platform/platform-cert-manager-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/aws-root
terraform destroy -var-file=env/dev.tfvars
```

## Notes

- Terraform roots are intentionally separated to handle bootstrap sequencing cleanly.
- The downstream cluster can either reuse AWS network data from `aws-root` remote state or accept dedicated AWS networking values.
- This repository is designed as a practical platform engineering portfolio project rather than production-ready infrastructure.

## Disclaimer

This repository is a **learning and experimentation project** designed to demonstrate a platform engineering workflow using Terraform, Rancher, and RKE2.

It is **not intended to represent production-ready infrastructure**.
