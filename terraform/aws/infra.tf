
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.prefix}-vpc" }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.prefix}-rt-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
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

resource "aws_vpc_security_group_ingress_rule" "k8s_api" {
  security_group_id = aws_security_group.rancher.id
  ip_protocol       = "tcp"
  from_port         = 6443
  to_port           = 6443
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
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    apt-get update -y
    apt-get install -y curl ca-certificates

    # Récupère l'IP publique via AWS Instance Metadata Service v2 (IMDSv2)
    TOKEN="$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")"

    PUBLIC_IP="$(curl -s -H "X-aws-ec2-metadata-token: $${TOKEN}" \
      http://169.254.169.254/latest/meta-data/public-ipv4)"

    echo "Detected PUBLIC_IP=$${PUBLIC_IP}"

    # Prépare la conf k3s pour inclure l'IP publique dans les SAN TLS
    mkdir -p /etc/rancher/k3s
    cat >/etc/rancher/k3s/config.yaml <<K3SCONFIG
    tls-san:
      - $${PUBLIC_IP}
    K3SCONFIG

    # Install k3s (server)
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${var.k3s_version}" sh -s - server

    # Make kubeconfig readable by ubuntu user
    mkdir -p /home/ubuntu/.kube
    chmod 644  /etc/rancher/k3s/k3s.yaml
    cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
    chown -R ubuntu:ubuntu /home/ubuntu/.kube
  EOF


  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name    = "${var.prefix}-rancher-server"
    Creator = "rancher-perf-provisioning"
  }
}

resource "aws_eip" "rancher_server" {
  domain = "vpc"
  instance = aws_instance.rancher_server.id
  tags = {
    Name = "${var.prefix}-rancher-eip"
  }
}

resource "aws_eip_association" "rancher_server" {
  instance_id   = aws_instance.rancher_server.id
  allocation_id = aws_eip.rancher_server.id
  depends_on    = [aws_instance.rancher_server]


}



