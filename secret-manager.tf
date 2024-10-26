locals {
  secret_manager_template_file = abspath(pathexpand("flux-secret-manager.yaml.tpl"))
  secret_manager_template_vars = merge(
    {
      secret_manager : var.secret_manager
    },
    local.manifests_template_vars
  )
}

locals {
  secret_manager_patch = var.secret_manager.name != "none" ? templatefile(local.secret_manager_template_file, local.secret_manager_template_vars) : ""
}
