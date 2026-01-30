
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.prefix}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.prefix}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
}

resource "aws_security_group" "rancher" {
  name        = "${var.prefix}-rancher-sg"
  description = "Rancher server + k8s nodes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name      = "${var.prefix}-rancher-sg"
    ManagedBy = "terraform"
  }
}


resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.rancher.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.admin_cidr_norm
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.rancher.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.admin_cidr_norm
}

resource "aws_vpc_security_group_ingress_rule" "intra" {
  security_group_id            = aws_security_group.rancher.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.rancher.id
}


resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.rancher.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
#resource "aws_eip" "rancher_server" {
#  vpc = true
#
#  tags {
#    Name = aws_instance.rancher_server.tags.Name
#  }
#
#  timeouts {
#    read = "1m"
#  }
#}
# AWS EC2 instance for creating a two node RKE cluster and installing the Rancher server
resource "aws_instance" "rancher_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.rancher_server_instance_type
  key_name                    = var.ec2_keypair
  vpc_security_group_ids      = [aws_security_group.rancher.id]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.prefix}-rancher-server"
    Creator = "rancher-perf-provisioning"
  }
}

resource "aws_eip" "rancher_server" {
  domain = "vpc"
  tags = {
    Name = "${var.prefix}-rancher-eip"
  }
}

resource "aws_eip_association" "rancher_server" {
  instance_id   = aws_instance.rancher_server.id
  allocation_id = aws_eip.rancher_server.id
  depends_on    = [aws_instance.rancher_server]


}


module "rancher_server" {
  source                        = "../rancher/rancher-server"
  node_public_ip                = aws_eip_association.rancher_server.public_ip
  node_internal_ip              = aws_instance.rancher_server.private_ip
  node_username                 = var.ssh_user
  ssh_private_key_pem           = file(var.ssh_private_key_file)
  rancher_kubernetes_version    = var.rancher_kubernetes_version
  cert_manager_version          = var.cert_manager_version
  rancher_version               = var.rancher_version
  rancher_server_dns            = var.rancher_server_dns
  rancher_server_admin_password = var.rancher_server_admin_password
  prefix                        = var.prefix
}

module "rancher_rke" {
  source               = "../rancher/rancher-rke"
  username             = var.ssh_user
  rancher_server_dns   = var.rancher_server_dns
  rancher_server_token = module.rancher_server.rancher_server_token

  workload_cluster_name   = var.workload_cluster_name
  docker_version          = var.docker_version
  ec2_security_group_name = aws_security_group.rancher.name
  ec2_keypair             = var.ec2_keypair
  prefix                  = var.prefix
  instance_type           = var.workload_nodes_instance_type
  rancher_aws_access_key  = var.rancher_aws_access_key
  rancher_aws_secret_key  = var.rancher_aws_secret_key
  aws_region              = var.aws_region
  aws_zone                = var.aws_zone
  aws_subnet_id           = aws_instance.rancher_server.subnet_id
  aws_vpc_id              = aws_vpc.main.id
}


