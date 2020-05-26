variable "vault_mount_root" {
  type        = string
  description = "Root CA Path"
}

variable "server_cert_domain" {
  type        = string
  description = "Cert domain"
}

variable "pki_path" {
  type        = string
  description = "PKI path"
}


variable "organization" {
  type        = string
  description = "organization for generated CAs"
}

variable "ou" {
  type        = string
  description = "ou for generated CAs"
}
