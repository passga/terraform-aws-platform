# Rancher on k3s on AWS (Terraform)

This project provisions a **k3s** server on **AWS** and deploys **Rancher** with:
- **Traefik** as Ingress Controller (k3s default)
- **cert-manager** for TLS
- **Let’s Encrypt** (**staging** or **production**)
- Rancher served with a **trusted public certificate** (no `insecure` mode)

---

## Prerequisites

### AWS
- An **AWS account**
- An IAM user or role with permissions to create EC2 / networking resources
- AWS credentials exported as environment variables:

```bash
export AWS_ACCESS_KEY_ID="xxxxxxxxxxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# optional
export AWS_DEFAULT_REGION="eu-west-3"
```

---

### Local tools
- `terraform` (>= 1.4)
- `kubectl`
- `helm` (>= 3)
- `curl`, `bash`

---

## Project layout

```
terraform/
├── aws/                      # AWS infra (EC2/VPC/etc.)
├── kube/                     # generated kubeconfig (k3s.yaml)
├── stacks/
│   └── cert-manager/         # cert-manager + CRDs (separate state)
└── rancher/
    └── rancher-server/       # ClusterIssuer + Certificate + Rancher + bootstrap (separate state)
tools/
└── scripts/
    └── fetch-kubeconfig.sh   # retrieves k3s kubeconfig from the server
```

> cert-manager and Rancher are intentionally split into **separate Terraform states**
> to avoid CRD ordering issues.

---

## 1) Provision AWS infrastructure (k3s server)

```bash
cd terraform/aws
terraform init
terraform apply -var-file=../../env/dev.tfvars
```

Terraform outputs include:
- `public_ip`
- `rancher_hostname`

---

## 2) Fetch kubeconfig from the k3s server

```bash
IP=$(terraform output -raw public_ip)
HOST=$(terraform output -raw rancher_hostname)

../../tools/scripts/fetch-kubeconfig.sh "$IP" ../../terraform/kube/k3s.yaml
```

Configure kubectl:

```bash
export KUBECONFIG=../../terraform/kube/k3s.yaml
kubectl get ns
```

---

## 3) Install cert-manager (CRDs)

```bash
cd ../stacks/cert-manager
terraform init
terraform apply -var-file=../../../env/dev.tfvars   -var="kubeconfig_path=../kube/k3s.yaml"
```

---

## 4) Deploy Rancher

```bash
cd ../../rancher/rancher-server
terraform init
terraform apply -var-file=../../../env/dev.tfvars   -var="kubeconfig_path=../../kube/k3s.yaml"   -var="rancher_hostname=${HOST}"
```

Terraform outputs:
- `rancher_server_url`
- `rancher_admin_password` (sensitive)
- Rancher API tokens (sensitive)

---

## TLS / Let’s Encrypt

### Default: staging
Staging is used by default to avoid rate limits while iterating.

### Switch to production

```bash
terraform apply -var="letsencrypt_environment=production"
```

If switching from staging to production, force re-issuance:

```bash
kubectl -n cattle-system delete certificate rancher-tls
kubectl -n cattle-system delete secret rancher-tls
terraform apply -var="letsencrypt_environment=production"
```

---

## Access Rancher

Open:

```
https://<rancher_hostname>
```

Admin password:

```bash
terraform output -raw rancher_admin_password
```

---

## Re-deploy Rancher

```bash
terraform apply -replace=helm_release.rancher_server
```

---

## Cleanup

Run `terraform destroy` in each Terraform state directory (AWS / cert-manager / rancher-server):

```bash
terraform destroy
```
