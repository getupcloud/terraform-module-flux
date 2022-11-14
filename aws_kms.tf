data "kubectl_file_documents" "flux-git-repository-kms" {
  count   = local.manifests_template_vars.modules.kms.enabled ? 1 : 0
  content = templatefile(abspath(pathexpand("flux-kms.yaml.tpl")), local.manifests_template_vars)
}

resource "kubectl_manifest" "flux-git-repository-kms" {
  count            = local.manifests_template_vars.modules.kms.enabled ? 1 : 0
  depends_on       = [kubectl_manifest.flux]
  yaml_body        = data.kubectl_file_documents.flux-git-repository-kms[0].documents[0]
  wait_for_rollout = var.wait
  wait             = var.wait
}
