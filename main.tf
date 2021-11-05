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
  wait_for_rollout   = var.wait
  wait               = var.wait
}

###
### Initial Git Repository
###

locals {
  flux_template_vars = {
    git_repository_name = var.git_repository_name
    namespace           = var.namespace
    git_repo            = var.git_repo
    manifests_path      = var.manifests_path
    reconcile_interval  = var.reconcile_interval
    identity            = trimspace(file(abspath(pathexpand(var.identity_file))))
    identity_pub        = trimspace(file(abspath(pathexpand(var.identity_pub_file))))
    known_hosts         = trimspace(file(abspath(pathexpand(var.known_hosts_file))))
  }

  git_repository_template = var.git_repo == "" ? "" : abspath(pathexpand(var.git_repository_template))
  git_repository_data     = var.git_repo == "" ? "" : templatefile(local.git_repository_template, local.flux_template_vars)
}

data "kubectl_file_documents" "flux-git-repository" {
  content = local.git_repository_data
}

resource "kubectl_manifest" "flux-git-repository" {
  depends_on = [kubectl_manifest.flux]
  for_each = {
    for i in [for j in data.kubectl_file_documents.flux-git-repository.documents : yamldecode(j)] :
    "${i.kind}_${try(format("%s_", i.metadata.namespace), "")}${i.metadata.name}" => i
  }
  yaml_body        = yamlencode(each.value)
  wait_for_rollout = var.wait
  wait             = var.wait
}

###
### Cluster Manifests
###

resource "local_file" "cluster-manifests" {
  for_each = {
    for tpl in fileset("${path.root}/manifests", "**")
      : tpl => templatefile("${path.root}/manifests/${tpl}", var.cluster_template_vars)
      if substr(tpl, -4, -1) == ".tpl"
    }
  filename = trimsuffix("${path.root}/manifests/${each.key}", ".tpl")
  content  = each.value
}
