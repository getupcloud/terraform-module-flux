terraform {
  required_providers {
    #kubectl = {
    #  source  = "gavinbunney/kubectl"
    #  version = "~> 1"
    #}

    kubernetes = {
      version = "~> 2.33"
    }

    kustomization = {
      source  = "kbst/kustomization"
      version = "< 1"
    }
  }
}
