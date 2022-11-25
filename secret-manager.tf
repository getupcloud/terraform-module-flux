data "kubectl_file_documents" "secret-manager" {
  count = var.secret_manager.name != "none" ? 1 : 0
  content = templatefile(
    abspath(pathexpand("flux-secret-manager-${var.secret_manager.name}.yaml.tpl")),
  merge({ secret_manager : var.secret_manager }, local.manifests_template_vars))
}

resource "kubectl_manifest" "secret-manager" {
  count            = var.secret_manager.name != "none" ? 1 : 0
  depends_on       = [kubectl_manifest.flux]
  yaml_body        = data.kubectl_file_documents.secret-manager[0].documents[0]
  wait_for_rollout = var.wait
  wait             = var.wait
}
