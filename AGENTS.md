# AGENTS.md

This repository demonstrates how to provision a Kubernetes platform on AWS using Terraform and Rancher.

## Architecture

Terraform provisions AWS infrastructure and a bootstrap `k3s` cluster.  
That bootstrap cluster runs Rancher, which then provisions a downstream RKE2 cluster on AWS using EC2 instances.

## Components

- Terraform
- AWS EC2
- k3s
- Rancher
- RKE2 Kubernetes
- aws-cloud-controller-manager
- Traefik
- AWS Network Load Balancer
- Argo CD
- cert-manager
- Let's Encrypt TLS

## Validated Workflow

Terraform
→ AWS infrastructure + bootstrap EC2 node
→ bootstrap `k3s`
→ cert-manager + Let's Encrypt `ClusterIssuer`
→ Rancher
→ downstream RKE2 on AWS
→ `aws-cloud-controller-manager`
→ Traefik customized via `HelmChartConfig`
→ `Service` type `LoadBalancer`
→ AWS NLB
→ Argo CD via Traefik

## Do Not Reintroduce

- `kube-apiserver-arg = ["cloud-provider=external"]`
- `node-labels=node-role.kubernetes.io/worker=true`
