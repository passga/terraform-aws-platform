terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "1.22.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    sshcommand = {
      source  = "invidian/sshcommand"
      version = "0.2.2"
    }
  }
  required_version = ">= 1.6.0"
}
