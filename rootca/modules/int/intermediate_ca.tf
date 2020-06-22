# Create a mount point for the Intermediate CA.
resource "vault_mount" "pki_int" {
    type = "pki"
    path = var.pki_path
    default_lease_ttl_seconds = 2628000
    max_lease_ttl_seconds = 2628000
    description = "Intermediate Authority for ${var.server_cert_domain}"
}
#
# Step 1
#
# Create a CSR (Certificate Signing Request)
resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
  depends_on = [ vault_mount.pki_int ]

  backend = vault_mount.pki_int.path
  #backend = var.vault_mount_root
  type = "exported"
  # This appears to be overwritten when the CA signs this cert, I'm not sure
  # the importance of common_name here.
  common_name = "Intermediate Certificate"
  #common_name = "${var.server_cert_domain} Intermediate Certificate"
  format = "pem"
  private_key_format = "der"
  key_type = "rsa"
  key_bits = "4096"
}
#
# Step 2
#
# Have the Root CA Sign our CSR
resource "vault_pki_secret_backend_root_sign_intermediate" "intermediate" {
  depends_on = [ vault_pki_secret_backend_intermediate_cert_request.intermediate ]
  backend = var.vault_mount_root

  csr = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
  common_name = var.server_cert_domain
  exclude_cn_from_sans = true
  ou                   = var.ou
  organization         = var.organization
  # Note that I am asking for 8 years here, since the vault_mount.root has a max_lease_ttl of 5 years
  # this 8 year request is shortened to 5.
  ttl = 252288000 #8 years
}

resource "vault_pki_secret_backend_role" "master" {
  backend  = vault_mount.pki_int.path

  name           = "master"
  allow_any_name = true
  allow_ip_sans  = true

  max_ttl = var.cert_ttl
  ttl     = var.cert_ttl

  allowed_domains = [
   "kube-apiserver",
   "kube-apiserver-kubelet-client"
  ]

  #allowed_uri_sans = concat(apiserver_hostnames, [
  allowed_uri_sans = [
   "kubernetes.default.svc.cluster.local",
   "kubernetes.default.svc.cluster",
   "kubernetes.default.svc",
   "kubernetes.default",
   "kubernetes",
  ]

  key_usage = ["DigitalSignature", "KeyEncipherment"]
  # ServerAuth is required for kube-apiserver cert, ClientAuth for kube-apiserver-kubelet-client
  ext_key_usage = ["ServerAuth", "ClientAuth"]
}

resource "vault_policy" "issue_cert" {
  name = "issue_cert"

  policy = <<EOT
path "${vault_mount.pki_int.path}/issue/${vault_pki_secret_backend_role.master.name}"
 {
  capabilities = ["create", "update"]
}
EOT
}

resource "vault_token_auth_backend_role" "issue-cert" {
  role_name = "issue-cert"
  allowed_policies    = [vault_policy.issue_cert.name]
  token_policies    = [vault_policy.issue_cert.name]
  #token_policies    = [vault_policy.issue_certpki_role.name]
}

resource "vault_kubernetes_auth_backend_role" "issue-cert" {
  backend                          = var.kubernetes_auth_path
  role_name                        = "issue-cert"
  bound_service_account_names      = ["${var.kubernetes_sa}"]
  bound_service_account_namespaces = ["${var.kubernetes_namespace}"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.issue_cert.name]
  #token_policies                   = ["default", "issue-cert"]
}

resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
 backend = vault_mount.pki_int.path

 certificate = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

output "intermediate_ca" {
  value = vault_pki_secret_backend_root_sign_intermediate.intermediate.certificate
}

output "intermediate_key"  {
  value = "${vault_pki_secret_backend_intermediate_cert_request.intermediate.private_key}"
}
