terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2"
    }

    kubernetes = {
      version = "~> 2.33"
    }

    kustomization = {
      source  = "kbst/kustomization"
      version = "< 1"
    }
  }
}
