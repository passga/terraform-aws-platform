
locals {
  rancher_hostname = "rancher.${aws_eip.rancher_server.public_ip}.nip.io"
}