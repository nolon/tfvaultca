# Create a mount point for the Root Certficate Authority.
resource "vault_mount" "root" {
    type = "pki"
    path = "pki-root-ca"
    default_lease_ttl_seconds = 31556952 # 1 years
    max_lease_ttl_seconds = 157680000 # 5 years
    description = "Root Certificate Authority"
}
resource "vault_mount" "root" {
    type = "pki"
    path = "pki-root-ca"
    default_lease_ttl_seconds = 31556952 # 1 years
    max_lease_ttl_seconds = 157680000 # 5 years
    description = "Root Certificate Authority"
}


# Modify the mount point and set URLs for the issuer and crl.
resource "vault_pki_secret_backend_config_urls" "config_urls" {
  depends_on = [ vault_mount.root ]  
  backend              = vault_mount.root.path
  issuing_certificates = ["http://lovault.${var.server_cert_domain}:8200/v1/pki/ca"]
  crl_distribution_points= ["http://lovault.${var.server_cert_domain}:8200/v1/pki/crl"]
}

# if you want to create the root cert in VAULT and never expose the 
# private key to the local machine use this route. 

resource "vault_pki_secret_backend_root_cert" "ca-cert" {
  depends_on = [vault_pki_secret_backend_config_urls.config_urls]    
  backend = vault_mount.root.path

  type = "exported"
  common_name = "${var.server_cert_domain} Root CA"
  ttl = "262800h"
  format = "pem"
  private_key_format = "der"
  key_type = "rsa"
  key_bits = "4096"
  exclude_cn_from_sans = true
  ou = "NNI"
  organization = "Swisscom"

}

resource local_file ca_file_vault {
    sensitive_content = vault_pki_secret_backend_root_cert.ca-cert.certificate
    filename = "${path.root}/output/certs/NNI-CA.pem"
    file_permission = "0400"
}

