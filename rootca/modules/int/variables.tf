variable "vault_mount_root" {
  type        = string
  description = "Root CA Path"
}

variable "server_cert_domain" {
  type        = string
  description = "Cert domain"
}

variable "kubernetes_namespace" {
  type        = string
  description = "PKI path"
}

variable "kubernetes_sa" {
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

variable "cert_ttl" {
  type        = string
  description = "INT Cert TTL"
}
