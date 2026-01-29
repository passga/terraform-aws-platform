# Performance environment provisioning

Provision Rancher management server in your infrastructure provider of choice.

**You will be responsible for any and all infrastructure costs incurred by these resources.**
As a result, this repository minimizes costs by standing up the minimum required resources for a given provider.
Use Vagrant to run Rancher locally and avoid cloud costs.

## Cloud perf-provisioning

perf-provisionings are provided for [**Amazon Web Services** (`aws`)](aws).

**You will be responsible for any and all infrastructure costs incurred by these resources.**

Each perf-provisioning will install a Rancher on a single-node k3s cluster, then will provision another 2-node workload cluster using a Custom cluster in Rancher.
This setup provides easy access to the core Rancher 

### Requirements - Cloud

- Terraform >=0.13.0
- Credentials for the cloud provider used for the perf-env-provisioning

### Deploy

To begin with any perf-provisioning, perform the following steps:

1. Clone or download this repository to a local folder
1. Choose a cloud provider and navigate into the provider's folder
1. Copy or rename `terraform.tfvars.example` to `terraform.tfvars` and fill in all required variables
1. Run `terraform init`
1. Run `terraform apply`

When provisioning has finished, terraform will output the URL to connect to the Rancher server.
Two sets of Kubernetes configurations will also be generated:
- `kube_config_server.yaml` contains credentials to access the RKE cluster supporting the Rancher server
- `kube_config_workload.yaml` contains credentials to access the provisioned workload cluster

For more details on each cloud provider, refer to the documentation in their respective folders.

### Remove

When you're finished exploring the Rancher server, use terraform to tear down all resources in the perf-provisioning.

**NOTE: Any resources not provisioned by the perf-provisioning are not guaranteed to be destroyed when tearing down the perf-provisioning.**
Make sure you tear down any resources you provisioned manually before running the destroy command.

Run `terraform destroy -auto-approve` to remove all resources without prompting for confirmation.
