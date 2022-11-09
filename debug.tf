resource "local_file" "debug-flux" {
  count    = var.debug == true ? 1 : 0
  filename = ".debug-flux.json"
  content = jsonencode({
    flux : {
      version : var.flux_version
      git_repository_template : var.git_repository_template
      git_repository_name : var.git_repository_name
      wait : var.wait
      install_on_okd : var.install_on_okd
      debug : var.debug
      namespace : var.namespace
      git_repo : var.git_repo
      git_branch : var.git_branch
      manifests_path : var.manifests_path
      reconcile_interval : var.reconcile_interval
      identity : trimspace(file(abspath(pathexpand(var.identity_file))))
      identity_pub : trimspace(file(abspath(pathexpand(var.identity_pub_file))))
      known_hosts : trimspace(file(abspath(pathexpand(var.known_hosts_file))))

    }
    manifests_template_vars : local.manifests_template_vars
  })
}
