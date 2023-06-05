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

data "kustomization_overlay" "flux-manifests" {
  resources = compact([
    abspath(pathexpand(var.flux_install_file != "" ? var.flux_install_file : "${path.module}/manifests/install-${var.flux_version}.yaml")),
    var.install_on_okd ? abspath(pathexpand("${path.module}/manifests/okd-manifests.yaml")) : ""
  ])

  patches {
    target {
      kind           = "Deployment"
      label_selector = "control-plane=controller"
    }

    patch = <<-EOF
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: all
      spec:
        template:
          spec:
            tolerations:
            - key: dedicated
              value: infra
              effect: NoSchedule

            affinity:
              nodeAffinity:
                preferredDuringSchedulingIgnoredDuringExecution:
                - weight: 100
                  preference:
                    matchExpressions:
                    - key: node-role.kubernetes.io/infra
                      operator: Exists
                - weight: 90
                  preference:
                    matchExpressions:
                    - key: role
                      operator: In
                      values:
                      - infra
    EOF
  }

  dynamic "patches" {
    for_each = var.secret_manager.name != "none" ? [var.secret_manager.name] : []

    content {
      target {
        kind      = "ServiceAccount"
        name      = "kustomize-controller"
        namespace = var.namespace
      }

      patch = data.kubectl_file_documents.secret-manager[0].documents[0]
    }
  }

  # Update Flux manifests so pods can run on Openshift
  # Reference: https://github.com/fluxcd/website/blob/main/content/en/docs/use-cases/openshift.md
  dynamic "patches" {
    for_each = var.install_on_okd ? ["okd"] : []

    content {
      target {
        kind           = "Deployment"
        label_selector = "app.kubernetes.io/part-of=flux"
      }

      patch = <<-EOF
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: all
        spec:
          template:
            spec:
              containers:
                - name: manager
                  securityContext:
                    runAsUser: 65534
                    seccompProfile:
                      $patch: delete
      EOF
    }
  }
}

locals {
  manifests = [for i in data.kustomization_overlay.flux-manifests.manifests : yamldecode(i)]
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
  manifests_template_vars = merge({
    git_repository_name = var.git_repository_name
    namespace           = var.namespace
    git_repo            = var.git_repo
    git_branch          = var.git_branch
    manifests_path      = var.manifests_path
    reconcile_interval  = var.reconcile_interval
    identity            = trimspace(file(abspath(pathexpand(var.identity_file))))
    identity_pub        = trimspace(file(abspath(pathexpand(var.identity_pub_file))))
    known_hosts         = trimspace(file(abspath(pathexpand(var.known_hosts_file))))
  }, var.manifests_template_vars)

  git_repository_template = var.git_repo == "" ? "" : abspath(pathexpand(var.git_repository_template))
  git_repository_data     = var.git_repo == "" ? "" : templatefile(local.git_repository_template, local.manifests_template_vars)
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
    : tpl => templatefile("${path.root}/manifests/${tpl}", var.manifests_template_vars)
    if substr(tpl, -4, -1) == ".tpl"
  }
  filename = trimsuffix("${path.root}/manifests/${each.key}", ".tpl")
  content  = each.value
}
