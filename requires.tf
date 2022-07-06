terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1"
    }

    kustomization = {
      source  = "kbst/kustomization"
      version = "< 1"
    }
  }
}
