resource "local_file" "debug-flux" {
  count    = var.debug == true ? 1 : 0
  filename = ".debug-flux.json"
  content  = jsonencode({manifests_template_vars : local.manifests_template_vars})
}
