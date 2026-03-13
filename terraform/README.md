# Terraform Layout

This directory contains the Terraform implementation for the platform described in the repository root README.

It provisions:
- AWS networking and compute
- a k3s bootstrap cluster
- cert-manager and a Let's Encrypt `ClusterIssuer`
- Rancher installed via Helm
- a downstream RKE2 cluster provisioned by Rancher on AWS

## Architecture

```text
terraform/
├── aws-root/                          # AWS network + k3s bootstrap node
├── platform/platform-cert-manager-root/ # cert-manager installation
├── platform/platform-issuer-root/       # Let's Encrypt ClusterIssuer
├── rancher/rancher-server-root/         # Rancher installation and bootstrap
├── rancher/downstream-rke2-root/        # Downstream RKE2 cluster provisioning
└── modules/                             # Reusable Terraform modules
```

The Terraform code is intentionally split into multiple roots because infrastructure provisioning, kubeconfig generation, CRD installation, Helm releases, Rancher bootstrap, and downstream cluster creation cannot be applied reliably in a single step.

## Provisioning Flow

1. `aws-root` creates the VPC, subnet, security group, EC2 bootstrap node, and fetches the k3s kubeconfig.
2. `platform-cert-manager-root` installs cert-manager into the bootstrap cluster.
3. `platform-issuer-root` creates the Let's Encrypt `ClusterIssuer`.
4. `rancher-server-root` installs Rancher on k3s and bootstraps API access.
5. `downstream-rke2-root` connects to Rancher and provisions the downstream RKE2 cluster on AWS.

## Root Responsibilities

### `aws-root`

Creates the base AWS infrastructure and bootstrap cluster:
- VPC, subnet, route table, internet access
- security group rules for SSH, HTTPS, Kubernetes API, and optional HTTP-01
- EC2 instance for k3s
- kubeconfig retrieval for later Terraform stages

### `platform/platform-cert-manager-root`

Installs cert-manager into the bootstrap cluster using the Helm provider.

### `platform/platform-issuer-root`

Creates the Let's Encrypt `ClusterIssuer` used for Rancher ingress TLS.

### `rancher/rancher-server-root`

Installs Rancher with Helm on the k3s cluster and bootstraps Rancher credentials and API access.

### `rancher/downstream-rke2-root`

Uses the Rancher API to:
- create or reuse an AWS cloud credential
- define EC2 machine configuration
- provision control plane and worker machine pools
- create the downstream RKE2 cluster

## Prerequisites

- Terraform `>= 1.6`
- AWS credentials with permissions to create networking and EC2 resources
- an existing EC2 key pair and its private key for bootstrap SSH access
- `kubectl`, `scp`, and standard shell tooling available locally
- a Rancher hostname reachable from the internet, typically using `nip.io` for demos
- inbound port `80` open when using Let's Encrypt HTTP-01

## AWS Authentication

There are two separate AWS authentication concerns in this Terraform layout.

### 1. Terraform access to AWS

The `aws-root` and other AWS-backed Terraform resources use the standard AWS provider credential chain. A common local setup is:

```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="eu-west-3"
```

If you are using temporary credentials, also export:

```bash
export AWS_SESSION_TOKEN="YOUR_SESSION_TOKEN"
```

You can also authenticate with `AWS_PROFILE` if you use `~/.aws/credentials`.

### 2. Rancher machine provisioning on AWS

The downstream RKE2 cluster is created by Rancher, so Rancher also needs AWS credentials for EC2 machine provisioning. In `rancher/downstream-rke2-root`, use one of these options:
- set `cloud_credential_id` to reuse an existing Rancher cloud credential
- or set `access_key` and `secret_key` in `env/dev.tfvars`

## How To Deploy

Use the example `env/dev.tfvars.example` files in each root as templates.

```bash
cd terraform/aws-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd ../platform/platform-cert-manager-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd ../platform-issuer-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd ../../rancher/rancher-server-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd ../downstream-rke2-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

## How To Destroy

Destroy in reverse order:

```bash
cd terraform/rancher/downstream-rke2-root
terraform destroy -var-file=env/dev.tfvars

cd ../rancher-server-root
terraform destroy -var-file=env/dev.tfvars

cd ../../platform/platform-issuer-root
terraform destroy -var-file=env/dev.tfvars

cd ../platform-cert-manager-root
terraform destroy -var-file=env/dev.tfvars

cd ../../aws-root
terraform destroy -var-file=env/dev.tfvars
```

## Notes

- Some roots consume local Terraform remote state from earlier stages, especially `aws-root` and `rancher-server-root`.
- `downstream-rke2-root` can either reuse AWS network outputs from `aws-root` or accept dedicated AWS network values.
- Do not commit `.terraform/`, `terraform.tfstate*`, kubeconfig files, or secret-bearing `.tfvars` files.
