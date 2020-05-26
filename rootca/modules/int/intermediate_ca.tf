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
  common_name = "var.server_cert_domain Intermediate Certificate"
  exclude_cn_from_sans = true
  ou                   = var.ou
  organization         = var.organization
  # Note that I am asking for 8 years here, since the vault_mount.root has a max_lease_ttl of 5 years
  # this 8 year request is shortened to 5.
  ttl = 252288000 #8 years
 
}

resource "vault_pki_secret_backend_role" "k8s_master_role" {
  backend  = vault_mount.pki_int.path

  name           = "master"
  allow_any_name = true
  allow_ip_sans  = true

  max_ttl = var.cert_ttl
  ttl     = var.cert_ttl

  allowed_domains = [
  | "kube-apiserver",
  | "kube-apiserver-kubelet-client"
  ]

  allowed_uri_sans = concat(each.value.apiserver_hostnames, [
  | "kubernetes.default.svc.cluster.local",
  | "kubernetes.default.svc.cluster",
  | "kubernetes.default.svc",
  | "kubernetes.default",
  | "kubernetes",
  ])

  key_usage = ["DigitalSignature", "KeyEncipherment"]
  # ServerAuth is required for kube-apiserver cert, ClientAuth for kube-apiserver-kubelet-client
  ext_key_usage = ["ServerAuth", "ClientAuth"]
}

resource "vault_policy" "pki_role" {

  name = "pki_sign"

  policy = <<EOT
path "${vault_mount.pki_int.path}/issue/${vault_pki_secret_backend_role.etcd_master_role[each.key].name}"
 {
  capabilities = ["create", "update"]
}
}
EOT

resource "vault_approle_auth_backend_role" "master_authrole" {
  for_each = var.clusters
  backend  = var.approle_path

  role_name = "${each.key}_master"
  # we do not use a secret id and instead bind localhost as cidr for demo purposes
  bind_secret_id    = false
  token_bound_cidrs = ["127.0.0.1/32"]
  token_policies    = [vault_policy.pki_role_access.name]
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
