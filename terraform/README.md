![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4)
![Kubernetes](https://img.shields.io/badge/Kubernetes-RKE2-blue)
![Platform](https://img.shields.io/badge/Platform-Rancher-green)
![Cloud](https://img.shields.io/badge/Cloud-AWS-orange)

# Terraform execution guide

## Purpose

This directory contains the staged Terraform roots that execute the validated platform workflow in this repository.

This README is intentionally operational:

- it explains which Terraform roots to run
- it documents the required execution order
- it documents the downstream IAM and instance profile prerequisites
- it documents the validated ingress and AWS NLB path
- it gives short troubleshooting guidance for the validated setup

For the high-level architecture and project outcomes, use the repository root README.

## Terraform Roots

| Terraform root | Purpose | When to run |
| --- | --- | --- |
| `terraform/aws-root` | Create AWS network resources and the bootstrap EC2 node that installs `k3s` | First, before any Kubernetes or Rancher root |
| `terraform/platform/platform-cert-manager-root` | Install cert-manager on the bootstrap cluster | After `aws-root`, before issuer and Rancher |
| `terraform/platform/platform-issuer-root` | Create the Let's Encrypt `ClusterIssuer` for Rancher TLS | After cert-manager, before Rancher |
| `terraform/rancher/rancher-server-root` | Install and bootstrap Rancher on the bootstrap cluster | After issuer, before downstream cluster creation |
| `terraform/rancher/downstream-rke2-root` | Provision the Rancher-managed downstream RKE2 cluster on AWS | After Rancher is healthy and downstream IAM is ready |
| `terraform/rancher/downstream-ingress-root` | Customize packaged Traefik with `HelmChartConfig` and expose it through `LoadBalancer` | After the downstream cluster is ready |
| `terraform/platform/platform-public-dns-root` | Create and retain the delegated Route53 public zone and manage generic downstream app DNS records | After downstream ingress is in place, before or alongside app-specific DNS usage |
| `terraform/platform/platform-cert-manager-downstream-root` | Install cert-manager on the downstream cluster | After downstream ingress and before downstream issuer or HTTPS apps |
| `terraform/platform/platform-issuer-downstream-root` | Create the downstream Let's Encrypt `ClusterIssuer` for Traefik-exposed applications | After downstream cert-manager, before downstream HTTPS apps |
| `terraform/platform/platform-argocd-root` | Install Argo CD and expose it through Traefik ingress with TLS | After downstream issuer is in place |
| `terraform/rancher/downstream-project-root` | Create Rancher project and namespace resources | Last, after downstream cluster registration is complete |

## Validated Downstream Cluster Behavior

The current validated downstream AWS cloud-provider path is:

- `machine_global_config` includes `cloud-provider-name = "aws"`
- the control-plane selector uses `disable-cloud-controller = true`
- the control-plane selector uses `kube-controller-manager-arg = ["cloud-provider=external"]`
- the control-plane selector uses `kubelet-arg = ["cloud-provider=external"]`
- the worker selector uses `kubelet-arg = ["cloud-provider=external"]`
- `aws-cloud-controller-manager` is installed as part of the downstream cluster path

This is the current validated downstream AWS integration reflected by the repository.

## Recommended Apply Order

Run the Terraform roots in this order:

1. `terraform/aws-root`
2. `terraform/platform/platform-cert-manager-root`
3. `terraform/platform/platform-issuer-root`
4. `terraform/rancher/rancher-server-root`
5. `terraform/rancher/downstream-rke2-root`
6. `terraform/rancher/downstream-ingress-root`
7. `terraform/platform/platform-public-dns-root`
8. `terraform/platform/platform-cert-manager-downstream-root`
9. `terraform/platform/platform-issuer-downstream-root`
10. `terraform/platform/platform-argocd-root`
11. `terraform/rancher/downstream-project-root`

For each root that includes an `env/dev.tfvars.example`, create a local `env/dev.tfvars` before applying.

Example execution sequence:

```bash
cd terraform/aws-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/platform/platform-cert-manager-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/platform/platform-issuer-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/rancher/rancher-server-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/rancher/downstream-rke2-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/rancher/downstream-ingress-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/platform/platform-public-dns-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/platform/platform-cert-manager-downstream-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/platform/platform-issuer-downstream-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/platform/platform-argocd-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/rancher/downstream-project-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

## Recommended Destroy Order

Destroy in reverse order:

1. `terraform/rancher/downstream-project-root`
2. `terraform/platform/platform-argocd-root`
3. `terraform/platform/platform-issuer-downstream-root`
4. `terraform/platform/platform-cert-manager-downstream-root`
5. `terraform/rancher/downstream-ingress-root`
6. `terraform/rancher/downstream-rke2-root`
7. `terraform/rancher/rancher-server-root`
8. `terraform/platform/platform-issuer-root`
9. `terraform/platform/platform-cert-manager-root`
10. `terraform/aws-root`

Do not include `terraform/platform/platform-public-dns-root` in normal cluster destroy workflows. That root owns the persistent delegated Route53 hosted zone for downstream applications and uses `prevent_destroy` so it survives downstream cluster redeploys.

Example destroy sequence:

```bash
cd terraform/rancher/downstream-project-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/platform/platform-argocd-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/platform/platform-issuer-downstream-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/platform/platform-cert-manager-downstream-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/rancher/downstream-ingress-root
terraform destroy -var-file=env/dev.tfvars

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

## IAM And Instance Profile Prerequisites For Downstream Nodes

Downstream node IAM remains a manual prerequisite for the validated setup.

Before running `terraform/rancher/downstream-rke2-root`, you must create in AWS:

- one EC2 IAM role for downstream RKE2 nodes
- one EC2 instance profile associated with that role
- the validated custom policy `infra-dev-rke2-cloud-provider-aws` attached to that downstream node role

The Terraform and Rancher code in this repository do not create that downstream node IAM role or instance profile for you.

### IAM Checklist For The Validated Setup

The validated downstream AWS path relies on three distinct IAM pieces.

#### 1. Downstream node IAM role

This is the IAM role ultimately attached to the downstream EC2 instances through the instance profile.

It must:

- be assumable by EC2
- be associated with the downstream EC2 instance profile
- have the validated custom policy `infra-dev-rke2-cloud-provider-aws`

#### 2. Downstream EC2 instance profile

This is what Rancher attaches to the EC2 machines it creates.

It must:

- exist before running `terraform/rancher/downstream-rke2-root`
- be associated with the intended downstream node IAM role
- be passed by **name** through `downstream_node_instance_profile_name`
- never be passed by ARN

Example:

```hcl
downstream_node_instance_profile_name = "rke2-downstream-instance-profile"
```

#### 3. AWS identities that interact with the role

The AWS identity used by Terraform or by the Rancher cloud credential to launch downstream EC2 instances must have:

- `iam:PassRole` on the downstream node IAM role

The Terraform AWS identity must also have:

- `iam:GetInstanceProfile` on the existing instance profile

Without these permissions:

- Rancher may fail to launch the EC2 instances
- Terraform may fail to validate the instance profile before passing its name into Rancher

### Trust Policy Requirement

The downstream node IAM role must be assumable by EC2.

Expected trust relationship principal:

- `ec2.amazonaws.com`

If the trust policy is incorrect, the role may exist and the instance profile may exist, but the launched EC2 instances will not be able to use the intended role correctly.

### Required Runtime Permissions For The Downstream Node Role

The validated downstream node policy is:

- `infra-dev-rke2-cloud-provider-aws`

At a high level, it must cover:

- Auto Scaling describe permissions
- EC2 describe permissions
- `ec2:CreateSecurityGroup`
- `ec2:CreateTags`
- `ec2:ModifyInstanceAttribute`
- `ec2:AuthorizeSecurityGroupIngress`
- `ec2:RevokeSecurityGroupIngress`
- `ec2:DeleteSecurityGroup`
- `ec2:CreateRoute`
- `ec2:DeleteRoute`
- Elastic Load Balancing permissions required to create, describe, modify, and delete the AWS NLB and related target groups and listeners
- `iam:CreateServiceLinkedRole`
- `kms:DescribeKey`

The missing permission observed in practice was:

- `ec2:CreateTags` on `security-group/*`

When that permission was missing:

- `rke2-traefik` stayed in `EXTERNAL-IP: pending`
- the AWS NLB did not complete reconciliation

### Verifying The IAM Setup

Check that the instance profile exists:

```bash
aws iam get-instance-profile --instance-profile-name <instance-profile-name>
```

Check that the role exists:

```bash
aws iam get-role --role-name <role-name>
```

Check that the expected policy is attached:

```bash
aws iam list-attached-role-policies --role-name <role-name>
```

Expected result:

- the instance profile exists
- the instance profile contains the intended downstream node role
- the role has `infra-dev-rke2-cloud-provider-aws` attached

## IAM Prerequisites For Persistent Public DNS

Route53 permissions for `terraform/platform/platform-public-dns-root` are a separate IAM prerequisite from the downstream node IAM role and instance profile requirements above.

These permissions are required before creating the Route53 hosted zone for the delegated public subdomain used by downstream applications.

Validated practical note:

- the missing Route53 permissions observed during testing were `route53:CreateHostedZone`
- the missing Route53 permissions observed during testing were `route53:ListTagsForResource`

Typical Route53 permissions needed for this root are:

- `route53:CreateHostedZone`
- `route53:GetHostedZone`
- `route53:DeleteHostedZone`
- `route53:ListHostedZones`
- `route53:ListHostedZonesByName`
- `route53:ChangeResourceRecordSets`
- `route53:ListResourceRecordSets`
- `route53:GetChange`
- `route53:ListTagsForResource`

Operational note:

- the public DNS zone is persistent and should not be part of normal cluster destroy workflows, even though `route53:DeleteHostedZone` may still be needed for exceptional manual cleanup

## Validated Downstream Ingress Path

The validated downstream ingress path is:

```text
Traefik packaged with RKE2
-> customized by HelmChartConfig in terraform/rancher/downstream-ingress-root
-> Service type LoadBalancer
-> aws-cloud-controller-manager / AWS cloud provider integration
-> AWS Network Load Balancer
```

Operational notes:

- do not recreate `kube-system/rke2-traefik` as a separate Terraform-managed `Service`
- customize Traefik through `HelmChartConfig` named `rke2-traefik`
- `aws-cloud-controller-manager` is part of the validated downstream cluster path
- the current validated NLB workflow relies on the AWS cloud provider integration and `aws-cloud-controller-manager` only
- a `404` from the NLB before any ingress exists is expected and only means Traefik has no matching route yet

Argo CD is validated on top of that path through `terraform/platform/platform-argocd-root`, where it is exposed by a Traefik ingress in the downstream cluster.

### Validating Argo CD Access Before DNS Wiring

In practice, the validation sequence is:
## Persistent Public DNS Layer

The delegated public DNS root is `terraform/platform/platform-public-dns-root`.

It is intentionally generic and not coupled to Argo CD:

- it creates a public Route53 hosted zone for downstream applications
- it protects that hosted zone with `prevent_destroy`
- it manages downstream application DNS entries through a variable-driven `app_records` map
- it creates Route53 `CNAME` records that default to the current downstream Traefik LoadBalancer hostname from `terraform/rancher/downstream-ingress-root`
- it still allows per-record target hostname overrides for future non-default use cases
- it follows the repository-wide AWS provider pattern: use explicit `aws_region` when provided, otherwise fall back to `../../aws-root/terraform.tfstate`

Operational model:

- keep the hosted zone persistent even if the downstream cluster is destroyed and recreated
- when the downstream NLB changes after a redeploy, standard app records follow the new Traefik hostname on the next `platform-public-dns-root` apply without tfvars target edits

The root reads this output automatically from `terraform/rancher/downstream-ingress-root`:

- `traefik_load_balancer_hostname`

The initial `env/dev.tfvars.example` shows an application record such as `apps.example.test` that only sets `fqdn`, because the CNAME target defaults to the current downstream Traefik hostname.

### Public DNS Operator Workflow

Use this workflow for the initial setup:

1. Apply `terraform/rancher/downstream-ingress-root`.
2. Set `app_records` in `terraform/platform/platform-public-dns-root/env/dev.tfvars`.
3. Apply `terraform/platform/platform-public-dns-root`.
4. Read `hosted_zone_name_servers` from `platform-public-dns-root`.
5. In the parent DNS provider, add NS records for the delegated public subdomain in the parent DNS zone and point them to the Route53 name servers from `hosted_zone_name_servers`.
6. Do not change the parent domain name servers themselves.

Use this workflow when the downstream NLB changes after a redeploy:

1. Re-apply `terraform/rancher/downstream-ingress-root` if needed so its outputs reflect the current Traefik LoadBalancer hostname.
2. Re-apply `terraform/platform/platform-public-dns-root`.

Standard records that rely on the default target follow the current Traefik NLB automatically. Only records using explicit target override fields need manual target updates.

Do not destroy `terraform/platform/platform-public-dns-root` as part of normal cluster teardown, and do not change the parent DNS delegation again after the initial setup unless you intentionally recreate the hosted zone.

HTTPS for downstream applications is handled separately from this DNS root. The validated downstream TLS path for Argo CD is:

- apply `terraform/rancher/downstream-ingress-root` so Traefik is exposed through the AWS NLB path
- apply `terraform/platform/platform-cert-manager-downstream-root` so cert-manager runs in the downstream cluster
- apply `terraform/platform/platform-issuer-downstream-root` so the downstream `ClusterIssuer` exists
- apply `terraform/platform/platform-argocd-root` so Argo CD ingress requests and serves TLS
- test Argo CD over HTTPS first through the AWS NLB with the expected `Host` header, then through public DNS after delegation is in place

Example:

```bash
curl -I -H 'Host: argocd-dev.apps.example' http://<aws-nlb-hostname>
```
## Persistent Public DNS Layer

### Current Downstream TLS Model

The current validated downstream TLS model is one certificate per application hostname.

- one hostname per application
- one ingress per application hostname
- one TLS secret per application hostname
- one certificate per application hostname

This is the current validated behavior for downstream applications exposed through Traefik and public DNS in the delegated subdomain.

Wildcard or shared certificate support for the delegated public subdomain is not implemented yet.
Treat that as a current limitation and a future evolution path rather than a supported configuration in the current repository state.
A follow-up issue will track wildcard TLS support separately.

### Validate Downstream HTTPS

Downstream Argo CD is exposed through Traefik ingress, and the AWS NLB is in front of Traefik. Validate the full HTTPS path with these checks:

kubectl --kubeconfig <downstream-kubeconfig> -n cert-manager get pods
kubectl --kubeconfig <downstream-kubeconfig> get clusterissuer
kubectl --kubeconfig <downstream-kubeconfig> -n argocd get ingress argocd
kubectl --kubeconfig <downstream-kubeconfig> -n argocd get certificate,secret
dig +short <aws-nlb-hostname> | head -n 1
curl -kI --resolve argocd-dev.apps.example.test:443:<aws-nlb-ipv4-address> https://argocd-dev.apps.example.test/

Use an IPv4 address from the NLB hostname lookup with `--resolve` (it does not accept a DNS hostname as the third value).

Expected result:

- cert-manager pods are `Running` in the downstream cluster
- the downstream `ClusterIssuer` is `Ready=True`
- the Argo CD ingress advertises the expected hostname, ingress class, and TLS secret
- the Argo CD TLS secret exists in the `argocd` namespace
- the HTTPS request reaches Traefik and returns a non-`404` response for the Argo CD host

After public DNS is delegated and the app record exists, validate the public hostname directly:

```bash
curl -I https://argocd-dev.apps.example.test/
```

## Troubleshooting Notes

| Symptom | Check |
| --- | --- |
| Downstream nodes are not created by Rancher | Confirm the instance profile exists, `downstream_node_instance_profile_name` is a name not an ARN, the AWS identity has `iam:PassRole`, and Terraform can call `iam:GetInstanceProfile` |
| `rke2-traefik` stays in `EXTERNAL-IP: pending` | Confirm the downstream node role has `infra-dev-rke2-cloud-provider-aws`, including `ec2:CreateTags` on `security-group/*`, and that `downstream-ingress-root` customized the packaged Traefik service through `HelmChartConfig` |
| NLB returns `404` | This is expected before a matching ingress exists; confirm the NLB already points to the Traefik `LoadBalancer` service |
| `kube-apiserver` fails with `unknown flag: --cloud-provider` | Do not use `kube-apiserver-arg = ["cloud-provider=external"]` |
| `kubelet` fails when worker node labels are forced | Do not use `node-labels=node-role.kubernetes.io/worker=true` |
| Downstream registration fails even though Rancher is reachable | Confirm Rancher TLS was issued correctly and downstream nodes trust the Rancher certificate chain |