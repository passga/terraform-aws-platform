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

resource "aws_security_group" "main" {
  name        = "${var.prefix}-sg"
  description = "${var.prefix} securrity group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name      = "${var.prefix}-sg"
    ManagedBy = "terraform"
  }
}


resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.main.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = local.admin_cidr_norm
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.main.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.admin_cidr_norm
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  count             = var.allow_http_01 ? 1 : 0
  security_group_id =  aws_security_group.main.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = var.http_01_cidr
}

resource "aws_vpc_security_group_ingress_rule" "k8s_api" {
  security_group_id =  aws_security_group.main.id
  ip_protocol       = "tcp"
  from_port         = 6443
  to_port           = 6443
  cidr_ipv4         = local.admin_cidr_norm
}
resource "aws_vpc_security_group_ingress_rule" "internal" {
  security_group_id            = aws_security_group.main.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.main.id
}


resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.main.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

