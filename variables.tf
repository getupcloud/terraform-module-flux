variable "flux_version" {
  description = "Flux version to install"
  type        = string
  default     = "v0.28.4"
}

variable "namespace" {
  description = "Namespace to install flux"
  type        = string
  default     = "flux-system"
}

variable "git_repo" {
  description = "Git repository URL. Empty to ignore."
  type        = string
  default     = ""
}

variable "git_branch" {
  description = "Git repository branch."
  type        = string
  default     = "main"
}

variable "git_repository_template" {
  description = "GitRepository template file."
  type        = string
  default     = "flux-git-repository.yaml.tpl"
}

variable "git_repository_name" {
  description = "Name for GitRepository object"
  type        = string
  default     = "cluster"
}

variable "flux_template_vars" {
  description = "Template vars for use by flux bootstrap manifests"
  type        = any
  default     = {}
}

variable "manifests_path" {
  description = "Manifests dir inside GitRepository"
  type        = string
  default     = ""
}

variable "wait" {
  description = "Wait for all manifests to apply"
  type        = bool
  default     = true
}

variable "reconcile_interval" {
  description = "Reconcile interval for GitRepository"
  type        = string
  default     = "5m"
}

variable "identity_file" {
  description = "SSH deploy private key"
  type        = string
  default     = "identity"
}

variable "identity_pub_file" {
  description = "SSH deploy public key"
  type        = string
  default     = "identity.pub"
}

variable "known_hosts_file" {
  description = "SSH known hosts file"
  type        = string
  default     = "known_hosts"
}

variable "manifests_template_vars" {
  description = "Template vars for use by cluster manifests"
  type        = any
  default = {
    alertmanager_pagerduty_key : ""
    alertmanager_opsgenie_api_key : ""
  }
}
