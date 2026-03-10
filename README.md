
# performance-tooling

performance-tooling is a personal Platform Engineering / DevOps playground used to experiment with
Terraform, Kubernetes, Rancher and cloud infrastructure on AWS.

## Goals

- Provision infrastructure with Terraform
- Deploy a management Kubernetes cluster
- Install Rancher as cluster manager
- Provision downstream workload clusters (RKE2)
- Add platform services such as Vault
- Deploy demo workloads consuming platform services



## Current Architecture

```text

AWS
└── EC2
└── k3s management cluster
├── cert-manager
├── ClusterIssuer
└── Rancher
```

Future target:

```text

AWS
└── Management Cluster (k3s)
└── Rancher
└── Downstream Clusters (RKE2)
├── Vault
└── Demo workloads

```

## Repository Structure

```text
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

```


## Quick Start

Provision AWS + k3s

cd terraform/aws-root
terraform init
terraform apply

Retrieve kubeconfig

./tools/scripts/fetch-kubeconfig.sh

Install cert-manager

cd terraform/platform/platform-cert-manager-root
terraform apply

Create ClusterIssuer

cd terraform/platform/platform-issuer-root
terraform apply

Install Rancher

cd terraform/addons-root
terraform apply

---

## Roadmap

- Add downstream RKE2 clusters
- Deploy Vault
- Demonstrate secret injection
- Add demo workloads
- Add observability stack

---

## Disclaimer

This repository is a learning and experimentation project and not production ready.