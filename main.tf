###
### Install flux
###

resource "kubernetes_namespace_v1" "flux-namespace" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/instance" = "flux-system"
    }
  }
}

data "kustomization_overlay" "flux-manifests" {
  resources = compact([
    abspath(pathexpand(var.flux_install_file != "" ? var.flux_install_file : "${path.module}/manifests/install-${var.flux_version}.yaml")),
    var.install_on_okd ? abspath(pathexpand("${path.module}/manifests/okd-manifests.yaml")) : ""
  ])

  namespace = kubernetes_namespace_v1.flux-namespace.metadata[0].name

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

      patch = local.secret_manager_patch
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
  manifests = [for i in data.kustomization_overlay.flux-manifests.manifests : jsondecode(i)]
}

resource "kubernetes_manifest" "flux" {
  for_each = {
    for i in local.manifests :
    "${i.kind}_${try(format("%s_", i.metadata.namespace), "")}${i.metadata.name}" => i if i.kind != "Namespace"
  }

  manifest = each.value

  computed_fields = ["spec.hard", "spec.template.spec.containers", "metadata.annotations"]

  field_manager {
    force_conflicts = true
  }
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

  git_repository_template = var.git_repo == "" ? null : abspath(pathexpand(var.git_repository_template))
  git_repository_data     = var.git_repo == "" ? null : provider::kubernetes::manifest_decode_multi(templatefile(local.git_repository_template, local.manifests_template_vars))
}

resource "kubernetes_manifest" "flux-git-repository" {
  depends_on = [kubernetes_manifest.flux]

  for_each = {
    for i in local.git_repository_data :
    "${i.kind}_${try(format("%s_", i.metadata.namespace), "")}${i.metadata.name}" => i
  }

  manifest = each.value
}

###
### Cluster Manifests
###

locals {
  exclude_set = fileexists("${path.root}/manifests/exclude-templates.yaml") ? flatten([
    for i in yamldecode(file("${path.root}/manifests/exclude-templates.yaml"))
    : fileset("${path.root}/manifests/", i)
  ]) : []
}

resource "local_file" "cluster-manifests" {
  for_each = {
    for tpl in fileset("${path.root}/manifests", "**")
    : tpl => templatefile("${path.root}/manifests/${tpl}", var.manifests_template_vars)
    if(endswith(tpl, ".tpl") && !contains(local.exclude_set, tpl))
  }
  filename = trimsuffix("${path.root}/manifests/${each.key}", ".tpl")
  content  = each.value
}
