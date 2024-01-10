variable "private_key" {
  type    = string
  default = "my-private-key-path"
}

variable "gcp_auth_file" {
  default = "serviceaccount_json_path"
}
variable "shell_user" {
  default = "my_shell_user"
}

variable "zone" {
  type    = string
  default = "us-central1-c"
}

variable "project" {
  type    = string
  default = "my-gcp-project-id"
}

variable "machine_name" {
  default = "zfs"
}