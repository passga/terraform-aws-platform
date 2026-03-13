# AGENTS.md

This repository demonstrates how to provision a Kubernetes platform on AWS using Terraform and Rancher.

## Architecture

Terraform provisions AWS infrastructure and installs Rancher on a bootstrap cluster.  
Rancher then provisions a downstream RKE2 Kubernetes cluster using EC2 instances.

## Components

- Terraform
- AWS EC2
- Rancher
- RKE2 Kubernetes
- cert-manager
- Let's Encrypt TLS

## Workflow

Terraform
→ AWS infrastructure
→ Bootstrap Kubernetes cluster
→ Rancher installation
→ cert-manager + Let's Encrypt
→ Rancher machine pools
→ RKE2 downstream cluster