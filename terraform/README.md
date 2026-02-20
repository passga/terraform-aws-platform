 # Rancher on k3s (AWS) — Terraform PoC

A clean, reproducible Terraform PoC that provisions a **single-node k3s cluster on AWS EC2** and installs **Rancher** on top of it.

The repo is intentionally split into **multiple Terraform roots** to reflect real Terraform constraints (kubeconfig generation, CRD readiness, API readiness).

---

## What this PoC does

- Creates an AWS **VPC + public subnet + IGW + route table**
- Creates a Security Group with minimal ports:
  - `22` (SSH) — restricted to your admin CIDR
  - `443` (Rancher UI) — restricted to your admin CIDR
  - `6443` (Kubernetes API) — restricted to your admin CIDR
  - `80` (optional) — for ACME HTTP-01 if you decide to use it
- Provisions an EC2 instance + **Elastic IP**
- Installs **k3s** via cloud-init and configures `tls-san` to include the public IP
- Fetches kubeconfig locally (Terraform `local-exec`)
- Installs **cert-manager** (Helm) in a dedicated root (platform-style)
- Creates a **ClusterIssuer** (Let’s Encrypt) in a dedicated root
- Installs **Rancher** (Helm) + bootstraps admin credentials via the `rancher2` provider

---

## Repository layout

```
terraform/
  aws-root/                       # AWS + EC2 + k3s + fetch kubeconfig
  addons-root/                    # Rancher install + bootstrap (uses existing cert-manager + issuer)
  platform/
    platform-cert-manager-root/   # cert-manager installation (Helm)
    platform-issuer-root/         # ClusterIssuer creation (kubernetes_manifest)
  modules/
    aws-network/                  # VPC, subnet, routes, SG
    aws-k3s-node/                 # EC2 + EIP + cloud-init (k3s)
    k8s-cert-manager/             # cert-manager Helm release
    k8s-rancher-server/           # Rancher Helm release + rancher2_bootstrap
  kube/                           # generated kubeconfig (should not be committed)
```

---

## Prerequisites

- Terraform `>= 1.6`
- `kubectl`
- SSH keypair in AWS (EC2 Key Pair)
- AWS credentials configured via one of:
  - `AWS_PROFILE=...` (recommended)
  - `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`

> This PoC does **not** require `helm` installed locally (Terraform uses the Helm provider).

---

## Quick start

### 0) Create a local vars file

Create **one vars file per root** (recommended) or reuse a single file, but keep it simple.

Example for `aws-root` (create `terraform/aws-root/env/dev.tfvars`):

```hcl
# Naming / region
prefix            = "perf"
aws_region        = "eu-west-3"
availability_zone = "eu-west-3a"

# Access control
admin_cidr = "X.X.X.X/32"

# EC2 SSH
ssh_key_name    = "your-ec2-keypair-name"
ssh_private_key = "/home/you/.ssh/your_key"

# Optional (ACME HTTP-01)
allow_http_01 = true
http_01_cidr  = "0.0.0.0/0"
```

Example for `addons-root` (create `terraform/addons-root/env/dev.tfvars`):

```hcl
kubeconfig_path   = "../aws-root/kube/k3s.yaml"
rancher_hostname  = "rancher.<EIP>.nip.io"
letsencrypt_environment = "staging" # or "production"

# Only for bootstrap if TLS is not trusted yet
rancher_bootstrap_insecure = true
```

Example for `platform/platform-issuer-root` (create `terraform/platform/platform-issuer-root/env/dev.tfvars`):

```hcl
kubeconfig_path      = "../../aws-root/kube/k3s.yaml"
letsencrypt_email    = "you@example.com"
letsencrypt_environment = "staging" # or "production"
```

---

### 1) Provision AWS + k3s and fetch kubeconfig

```bash
cd terraform/aws-root
terraform init
terraform apply -auto-approve -var-file=./env/dev.tfvars
```

Outputs include the public IP. The root also fetches kubeconfig to:

- `terraform/aws-root/kube/k3s.yaml`

Validate:

```bash
kubectl --kubeconfig terraform/aws-root/kube/k3s.yaml get nodes
```

---

### 2) Install cert-manager

```bash
cd terraform/platform/platform-cert-manager-root
terraform init
terraform apply -auto-approve -var-file=./env/dev.tfvars
```

Check CRDs:

```bash
kubectl --kubeconfig terraform/aws-root/kube/k3s.yaml get crd | grep cert-manager | head
```

---

### 3) Create the ClusterIssuer

```bash
cd terraform/platform/platform-issuer-root
terraform init
terraform apply -auto-approve -var-file=./env/dev.tfvars
```

---

### 4) Install Rancher + bootstrap

```bash
cd terraform/addons-root
terraform init
terraform apply -auto-approve -var-file=./env/dev.tfvars
```

Get the generated admin password:

```bash
terraform output -raw rancher_admin_password
```

Open:

- `https://<rancher_hostname>`

---

## Notes and common pitfalls


### TLS readiness

If Rancher bootstrap fails with x509 errors, it is almost always one of:

- `rancher-tls` secret does not exist yet
- Traefik is serving a default cert (`*.traefik.default`) because the secret is missing
- you are still on Let’s Encrypt *staging* (trusted but different chain handling on some clients)

Your bootstrap flow should either:

- wait until the TLS secret exists and `curl https://<host>/ping` works **without** `-k`, or
- temporarily allow insecure bootstrap (`rancher_bootstrap_insecure=true`) and later turn it off

---

## Cleanup

Destroy in reverse order:

```bash
cd terraform/addons-root && terraform destroy -auto-approve -var-file=./env/dev.tfvars
cd terraform/platform/platform-issuer-root && terraform destroy -auto-approve -var-file=./env/dev.tfvars
cd terraform/platform/platform-cert-manager-root && terraform destroy -auto-approve -var-file=./env/dev.tfvars
cd terraform/aws-root && terraform destroy -auto-approve -var-file=./env/dev.tfvars
```

---

## What to keep out of git

Do **not** commit:

- `**/.terraform/`
- `**/terraform.tfstate*`
- any kubeconfig (`**/kube/*.yaml`)
- any `.tfvars` with secrets

---

## License

PoC / educational.
