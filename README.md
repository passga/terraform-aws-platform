![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4)
![Kubernetes](https://img.shields.io/badge/Kubernetes-RKE2-blue)
![Platform](https://img.shields.io/badge/Platform-Rancher-green)
![Cloud](https://img.shields.io/badge/Cloud-AWS-orange)

# terraform-aws-platform

## Overview

This repository captures a validated platform engineering workflow for building a Rancher-managed Kubernetes platform on AWS with Terraform.

The validated implementation covers:

- bootstrap `k3s` on AWS
- Rancher on the bootstrap cluster
- bootstrap cert-manager with a Let's Encrypt `ClusterIssuer` for Rancher TLS
- downstream RKE2 provisioned by Rancher on AWS
- `aws-cloud-controller-manager` in the downstream cluster
- downstream cert-manager
- downstream Let's Encrypt `ClusterIssuer`
- Traefik customized through `HelmChartConfig`
- Traefik exposed as `Service` type `LoadBalancer`
- AWS Network Load Balancer reconciliation
- delegated public DNS in Route53 for downstream applications
- downstream HTTPS/TLS for Traefik-exposed applications
- Argo CD exposed through Traefik ingress and validated through public HTTPS

## Current Downstream TLS Model

The current validated downstream TLS model for applications exposed through Traefik is hostname-specific.

- each downstream application is exposed through its own hostname
- each application hostname uses its own ingress
- each application hostname uses its own TLS secret
- each application hostname uses its own certificate

This is the currently validated behavior for downstream applications exposed through Traefik and the delegated public subdomain.

Wildcard or shared certificate support for the delegated public subdomain is not implemented yet.
Treat that as a current limitation of the repository, not as a supported path.
A follow-up issue will track wildcard TLS support as the next evolution of the downstream application TLS model.

## Validated Architecture

```text
+-----------------------------------------------------------------------------------+
|                                        AWS                                        |
|-----------------------------------------------------------------------------------|
| VPC / subnet / security groups                                                    |
| EC2 bootstrap node for k3s                                                        |
| EC2 downstream nodes for RKE2                                                     |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                              Bootstrap k3s cluster                                |
|-----------------------------------------------------------------------------------|
| cert-manager for Rancher TLS                                                      |
| ClusterIssuer (Let's Encrypt) for Rancher TLS                                     |
| Rancher                                                                           |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                        Rancher-managed downstream RKE2 cluster                     |
|-----------------------------------------------------------------------------------|
| Control plane and worker machine pools on AWS                                     |
| aws-cloud-controller-manager                                                      |
| cert-manager for downstream application TLS                                       |
| ClusterIssuer (Let's Encrypt) for downstream application TLS                      |
| Traefik packaged with RKE2, customized via HelmChartConfig                        |
| Service type LoadBalancer for rke2-traefik                                        |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                              AWS Network Load Balancer                            |
|-----------------------------------------------------------------------------------|
| NLB created from the Traefik Service type LoadBalancer                            |
| Traffic forwarded to Traefik                                                      |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                                  Ingress traffic                                  |
|-----------------------------------------------------------------------------------|
| Route53 delegated subdomain for downstream app hostnames                          |
| Traefik-exposed downstream applications served through HTTPS/TLS                  |
| Argo CD exposed through Traefik ingress                                           |
| Argo CD validated through public HTTPS on its delegated hostname                  |
+-----------------------------------------------------------------------------------+
```

## Key Validated Outcomes

With the current validated code path, this repository demonstrates:

- a bootstrap `k3s` cluster on AWS for Rancher
- Rancher served with cert-manager-managed TLS
- a Rancher-managed downstream RKE2 cluster on AWS
- external AWS cloud-provider integration through `aws-cloud-controller-manager`
- downstream cert-manager and downstream Let's Encrypt issuer resources for application TLS
- Traefik exposed by a Kubernetes `LoadBalancer` Service and reconciled to an AWS NLB
- a persistent Route53 delegated public DNS layer for downstream application hostnames
- downstream application exposure through Traefik ingress with validated HTTPS/TLS
- Argo CD deployed in the downstream cluster and validated through public HTTPS on its delegated hostname
- Rancher project and namespace resources created after cluster readiness

## Screenshot

![Rancher cluster dashboard](docs/rancher-cluster-dashboard.png)

## Why This Project Matters

This project shows a practical multi-stage platform build rather than an isolated Terraform demo. It validates the handoff from infrastructure provisioning to bootstrap cluster services, Rancher-based downstream provisioning, AWS cloud integration, and application exposure through Traefik and an AWS NLB.

It also captures the troubleshooting that made the validated path work in practice:

- downstream node IAM remains a manual prerequisite
- the validated downstream node policy is `infra-dev-rke2-cloud-provider-aws`
- a missing `ec2:CreateTags` permission on `security-group/*` caused `rke2-traefik` to stay in `EXTERNAL-IP: pending`
- `kube-apiserver-arg = ["cloud-provider=external"]` is not part of the validated setup
- `node-labels=node-role.kubernetes.io/worker=true` is not part of the validated setup
- a `404` from the NLB before any ingress exists is expected and only means Traefik has no matching route yet

## Repository Structure

```text
terraform/
├── README.md
├── aws-root/
├── modules/
├── platform/
└── rancher/
```

Use [terraform/README.md](terraform/README.md) as the operational guide for Terraform root order, apply and destroy steps, prerequisites, IAM setup, ingress behavior, and troubleshooting.

For public DNS, `terraform/platform/platform-public-dns-root` creates a Route53 hosted zone for a delegated public subdomain used by downstream applications. That root follows the same AWS provider pattern as the other downstream roots: use explicit `aws_region` when provided, otherwise fall back to `aws-root` remote state. Standard app records in that root follow the current downstream Traefik LoadBalancer hostname automatically through `downstream-ingress-root` remote state. The parent DNS provider only needs a one-time delegation step: add NS records for the delegated public subdomain in the parent DNS zone and point them to the Route53 name servers returned by Terraform. Do not change the parent domain name servers themselves. After that, downstream application DNS changes happen only in Route53, and the hosted zone is intentionally kept persistent across downstream cluster redeploys.
