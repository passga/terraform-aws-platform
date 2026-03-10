# performance-tooling

`performance-tooling` is a personal **Platform Engineering / DevOps playground** used to experiment with:

- Terraform
- Kubernetes
- Rancher
- Cloud infrastructure on AWS

The goal of this repository is to progressively build a **small but realistic Kubernetes platform stack**.

---

# Why this repository exists

This project is used to experiment with platform engineering concepts such as:

- infrastructure automation with Terraform
- Kubernetes cluster lifecycle management
- multi-cluster management with Rancher
- platform services such as Vault
- reproducible infrastructure environments

It serves as a **learning platform and technical sandbox**.

---

# Architecture

## Current architecture

```
AWS
└── EC2
    └── k3s management cluster
        ├── cert-manager
        ├── ClusterIssuer
        └── Rancher
```

The current setup deploys a **lightweight management cluster** running **k3s**.

This cluster hosts only **platform control components**.

---

## Target architecture

```
AWS
└── Management Cluster (k3s)
      └── Rancher
            └── Downstream Clusters (RKE2)
                  ├── Vault
                  └── Demo workloads
```

Future steps will introduce **downstream clusters managed by Rancher**.

Workloads and platform services will run on those clusters.

---

# Repository Structure

```
performance-tooling
├── terraform
│   ├── aws-root
│   │   └── AWS infrastructure provisioning (VPC, EC2, k3s node)
│   │
│   ├── addons-root
│   │   └── Kubernetes addons deployment (Rancher installation)
│   │
│   ├── platform
│   │   ├── platform-cert-manager-root
│   │   │   └── cert-manager installation
│   │   │
│   │   └── platform-issuer-root
│   │       └── ClusterIssuer creation
│   │
│   ├── modules
│   │   ├── aws-network
│   │   ├── aws-k3s-node
│   │   ├── k8s-cert-manager
│   │   └── k8s-rancher-server
│   │
│   └── kube
│       └── generated kubeconfig (not committed)
│
├── tools
│   └── helper scripts
│
└── README.md
```

Terraform is intentionally split into **multiple roots** to handle bootstrap constraints such as:

- kubeconfig generation
- Kubernetes API availability
- CRD dependencies
- platform component ordering

---

# Current Stack

The repository currently provisions:

- AWS networking
- EC2 instance running **k3s**
- kubeconfig retrieval
- **cert-manager**
- **Let's Encrypt ClusterIssuer**
- **Rancher Server**

This environment acts as the **platform management cluster**.

---

# Quick Start

## 1. Provision infrastructure

```
cd terraform/aws-root
terraform init
terraform apply
```

## 2. Retrieve kubeconfig

```
./tools/scripts/fetch-kubeconfig.sh
```

## 3. Install cert-manager

```
cd terraform/platform/platform-cert-manager-root
terraform apply
```

## 4. Create ClusterIssuer

```
cd terraform/platform/platform-issuer-root
terraform apply
```

## 5. Install Rancher

```
cd terraform/addons-root
terraform apply
```

Once deployed, Rancher UI becomes available.

---

# Roadmap

Next improvements planned:

- Provision **downstream RKE2 clusters via Rancher**
- Deploy **Hashicorp Vault**
- Demonstrate **secret injection into Kubernetes workloads**
- Add **demo applications**
- Add **observability stack (Prometheus / Grafana)**

---

# Disclaimer

This repository is a **learning and experimentation project** and is **not production-ready infrastructure**.