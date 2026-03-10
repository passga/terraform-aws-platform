
# Performance Tooling – Rancher on k3s with Terraform

This repository contains a Terraform-based Proof of Concept (PoC) used to deploy a minimal platform stack on AWS:

- AWS infrastructure
- k3s Kubernetes cluster
- cert-manager
- Rancher

The goal of the project is to experiment with platform engineering workflows and build a reproducible environment for testing Rancher and Kubernetes automation.

---

# Architecture Overview

The stack is provisioned in layers:

1. Infrastructure layer
   - AWS VPC
   - Subnet
   - Security Groups
   - EC2 instance running k3s

2. Platform layer
   - cert-manager
   - ClusterIssuer (Let's Encrypt)

3. Application layer
   - Rancher deployed via Helm

The deployment flow is intentionally separated because some components require resources created in previous stages (for example Kubernetes CRDs).

---

# Repository Structure

performance-tooling
│
├── terraform
│   ├── aws-root
│   │   └── Infrastructure provisioning (VPC, EC2, k3s node)
│   │
│   ├── addons-root
│   │   └── Kubernetes addons deployment
│   │
│   ├── modules
│   │   ├── aws-network
│   │   ├── aws-k3s-node
│   │   ├── k8s-cert-manager
│   │   └── k8s-rancher-server
│   │
│   └── kube
│       └── local kubeconfig (generated locally – not committed)
│
├── tools
│   └── helper scripts
│
└── README.md

---

# Prerequisites

You need the following tools installed:

- Terraform >= 1.6
- AWS CLI
- kubectl
- Helm
- SSH client

AWS credentials must be configured locally:

aws configure

---

# Deployment Workflow

## 1. Deploy infrastructure

cd terraform/aws-root

terraform init
terraform apply

This creates:

- VPC
- Security groups
- EC2 instance
- k3s cluster

It also outputs instructions to retrieve the kubeconfig.

---

## 2. Retrieve kubeconfig

scp ubuntu@<public-ip>:/home/ubuntu/k3s.yaml terraform/kube/k3s.yaml

Update the server endpoint inside the kubeconfig to use the public IP.

---

## 3. Deploy platform components

cd terraform/addons-root

terraform init
terraform apply

This deploys:

- cert-manager
- Let's Encrypt ClusterIssuer
- Rancher via Helm

---

# Access Rancher

After deployment, Rancher is available at:

https://rancher.<public-ip>.nip.io

The initial admin password can be retrieved via Terraform outputs:

terraform output rancher_admin_password

---

# Destroy the Environment

To avoid unnecessary AWS costs:

cd terraform/aws-root
terraform destroy

Also ensure that:

- Elastic IPs are released
- Volumes are removed

---

# Cost Notes

The current configuration uses:

- t3.medium instance
- ~15–20 GB EBS volume

Running continuously may cost around $30–40 per month.

To reduce costs:

- destroy the environment when not in use
- avoid leaving instances running overnight
- remove unused Elastic IPs

---

# Purpose of This Repository

This project is primarily a learning and experimentation environment focused on:

- Terraform modularization
- Kubernetes bootstrap automation
- Rancher installation automation
- cert-manager and TLS workflows

It is not intended for production usage.

---

# License

MIT License