

output "rancher_node_ip" {
  value = aws_eip_association.rancher_server.public_ip
}

output "rancher_server_ec2_instance_id" {
  value = aws_eip_association.rancher_server.instance_id
}


output "rancher_server_subnet_id" {
  value     = aws_instance.rancher_server.subnet_id
  sensitive = true
}

output "rancher_server_availability_zone" {
  value     = aws_instance.rancher_server.availability_zone
  sensitive = true
}

output "public_ip" {
  value = aws_eip.rancher_server.public_ip
}

output "ssh_command" {
  value = "ssh -i <YOUR_KEY> ubuntu@${aws_eip.rancher_server.public_ip}"
}

output "rancher_hostname" {
  value = "rancher.${aws_eip.rancher_server.public_ip}.nip.io"
}

