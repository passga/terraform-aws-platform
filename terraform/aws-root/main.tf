module "network" {
  source = "../modules/aws-network"
  admin_cidr        = var.admin_cidr
}

module "k3s_node" {
  source            = "../modules/aws-k3s-node"
  subnet_id         = module.network.aws_subnet_id
  sg_id             = module.network.aws_sg_id
  vpc_id            = module.network.aws_vpc_id
  availability_zone = var.availability_zone
  prefix            = var.prefix
  ssh_key_name      = var.ssh_key_name
  aws_region        = var.aws_region

}

resource "time_sleep" "wait_k3s_ready" {
  depends_on      = [module.k3s_node]
  create_duration = "60s"
}

resource "null_resource" "fetch_kubeconfig" {
  depends_on = [time_sleep.wait_k3s_ready]

  provisioner "local-exec" {
    command = <<EOT

set -e
mkdir -p ${path.root}/kube

scp -i ${var.ssh_private_key}\
  ubuntu@${module.k3s_node.public_ip}:/home/ubuntu/.kube/config \
  ${local.kubeconfig_path}

sed -i "s/127.0.0.1/${module.k3s_node.public_ip}/g" \
  ${local.kubeconfig_path}

chmod 600 ${local.kubeconfig_path}
EOT
  }
}

