

output "public_ip" {
  value = aws_eip.k3s.public_ip
}

output "ssh_command" {
  value = "ssh -i <YOUR_KEY> ubuntu@${aws_eip.k3s.public_ip}"
}

output "k3s_hostname" {
  value = "rancher.${aws_eip.k3s.public_ip}.nip.io"
}

