

# AWS EC2 instance for creating a two node RKE cluster and installing the Rancher server
resource "aws_instance" "k3s" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.k3s_node_instance_type
  key_name                    = var.ssh_key_name
  vpc_security_group_ids      = [var.sg_id]
  associate_public_ip_address = true
  subnet_id                   = var.subnet_id
  user_data                   = <<-EOF
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

resource "aws_eip" "k3s" {
  domain   = "vpc"
  instance = aws_instance.k3s.id
  tags = {
    Name = "${var.prefix}-rancher-eip"
  }
}

resource "aws_eip_association" "k3s" {
  instance_id   = aws_instance.k3s.id
  allocation_id = aws_eip.k3s.id
  depends_on    = [aws_instance.k3s]
}



