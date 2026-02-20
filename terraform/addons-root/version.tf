terraform {
  required_version = ">= 1.6.0"

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

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
