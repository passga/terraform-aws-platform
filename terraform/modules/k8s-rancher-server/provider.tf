terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 13.1"
    }

  }
}
