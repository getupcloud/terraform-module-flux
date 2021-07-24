###
### Install flux
###

resource "kubectl_manifest" "flux-namespace" {
  yaml_body = <<-EOF
    apiVersion: v1
    kind: Namespace
    metadata:
      labels:
        app.kubernetes.io/instance: flux-system
      name: ${var.namespace}
  EOF
}

data "kubectl_file_documents" "flux-manifests" {
  content = file(abspath(pathexpand("${path.module}/manifests/install-${var.flux_version}.yaml")))
}

locals {
  manifests = [for i in data.kubectl_file_documents.flux-manifests.documents : yamldecode(i)]
}

resource "kubectl_manifest" "flux" {
  for_each           = { for i in local.manifests : "${i.kind}_${try(format("%s_", i.metadata.namespace), "")}${i.metadata.name}" => i if i.kind != "Namespace" }
  override_namespace = kubectl_manifest.flux-namespace.name
  yaml_body          = yamlencode(each.value)
}

###
### Initial Git Repository
###

locals {
  template_vars = {
    name               = "flux"
    namespace          = var.namespace
    git_repo           = var.git_repo
    manifests_path     = var.manifests_path
    reconcile_interval = var.reconcile_interval
    identity           = trimspace(file(abspath(pathexpand(var.identity_file))))
    identity_pub       = trimspace(file(abspath(pathexpand(var.identity_pub_file))))
    known_hosts        = trimspace(file(abspath(pathexpand(var.known_hosts_file))))
  }

  git_repository_template = var.git_repo == "" ? "" : abspath(pathexpand(var.git_repository_template))
  git_repository_data     = var.git_repo == "" ? "" : templatefile(local.git_repository_template, local.template_vars)
}

data "kubectl_file_documents" "flux-git-repository" {
  content = local.git_repository_data
}

resource "kubectl_manifest" "flux-git-repository" {
  depends_on = [kubectl_manifest.flux]
  for_each   = {
    for i in [ for j in data.kubectl_file_documents.flux-git-repository.documents : yamldecode(j) ] :
      "${i.kind}_${try(format("%s_", i.metadata.namespace), "")}${i.metadata.name}" => i
    }
  yaml_body  = yamlencode(each.value)
}
