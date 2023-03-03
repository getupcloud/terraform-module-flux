locals {
  secret_manager_template_file = abspath(pathexpand("flux-secret-manager.yaml.tpl"))
  secret_manager_template_vars = merge(
    {
      secret_manager : var.secret_manager
    },
    local.manifests_template_vars
  )
}

data "kubectl_file_documents" "secret-manager" {
  count   = var.secret_manager.name != "none" ? 1 : 0
  content = templatefile(local.secret_manager_template_file, local.secret_manager_template_vars)
}

resource "kubectl_manifest" "secret-manager" {
  count            = var.secret_manager.name != "none" ? 1 : 0
  yaml_body        = data.kubectl_file_documents.secret-manager[0].documents[0]
  wait_for_rollout = var.wait
  wait             = var.wait
}
