#data "template_cloudinit_config" "k3s_server" {
#  gzip          = true
#  base64_encode = true
#

#
#  part {
#    content_type = "text/x-shellscript"
#    content      = templatefile("${path.module}/files/k3s-install.sh", { install_k3s_version = local.install_k3s_version, k3s_exec = local.server_k3s_exec, k3s_cluster_secret = local.k3s_cluster_secret, is_k3s_server = true, k3s_url = aws_lb.server-lb.dns_name, k3s_storage_endpoint = local.k3s_storage_endpoint, k3s_storage_cafile = local.k3s_storage_cafile, k3s_disable_agent = local.k3s_disable_agent, k3s_tls_san = local.k3s_tls_san, k3s_deploy_traefik = local.k3s_deploy_traefik })
#  }
#
#  part {
#    content_type = "text/x-shellscript"
#    content      = templatefile("${path.module}/files/ingress-install.sh", { install_nginx_ingress = local.install_nginx_ingress })
#  }
#
#  part {
#    content_type = "text/x-shellscript"
#    content      = templatefile("${path.module}/files/rancher-install.sh", { certmanager_version = local.certmanager_version, rancher_version = local.rancher_version, rancher_hostname = "${local.name}.${local.domain}", install_rancher = local.install_rancher, install_nginx_ingress = local.install_nginx_ingress, install_certmanager = local.install_certmanager })
#  }
#
#  part {
#    content_type = "text/x-shellscript"
#    content      = templatefile("${path.module}/files/register-to-rancher.sh", { is_k3s_server = true, install_rancher = local.install_rancher, registration_command = local.registration_command })
#  }
#}
