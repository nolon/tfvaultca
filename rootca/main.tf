# approle auth backend used by nodes to issue their certs
resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_auth_backend" "github" {
  type = "github"
}

resource "vault_mount" "ssh_host_signer" {
  path        = "ssh-host-signer"
  type        = "ssh"
  description = "SSH Secrets Engine (host)"
}

resource "vault_ssh_secret_backend_ca" "ssh_host_signer" {
  backend = vault_mount.ssh_host_signer.path
  generate_signing_key = true
}


resource "vault_mount" "ssh_client_signer" {
  path        = "ssh-client-signer"
  type        = "ssh"
  description = "SSH Secrets Engine (client)"
}


resource "vault_ssh_secret_backend_ca" "ssh_client_signer" {
  backend = vault_mount.ssh_client_signer.path
  generate_signing_key = true
}





resource "vault_policy" "terraform_roleid" {
  name = "tf-roleid-get"
  policy = <<EOT
  path "auth/approle/role/ansible-k8s/role-id" {
  capabilities = [ "read", "list" ]
}
EOT
}


resource "vault_policy" "ansible_secret_id" {
  name = "ansible-secretid-get"
  policy = <<EOT
  path "auth/approle/role/ansible-k8s/secret-id" {
  capabilities = [ "update" ]
}
EOT
}

resource "vault_approle_auth_backend_role" "terraform_roleid" {
  backend  = vault_auth_backend.approle.path

  role_name         = "ansible-k8s"
  role_id           = "d008afdd-be61-4f33-2aed-ef288bb1e723"
  bind_secret_id    = false
  token_bound_cidrs = ["127.0.0.1/32"]
  token_policies    = [vault_policy.terraform_roleid.name]
}


resource "vault_policy" "terraform_token_create" {
  name = "terraform-token-create"
  policy = <<EOT
  path "auth/token/create" {
  capabilities = [ "update" ]
}
EOT
}

module "ecp-silver-auth" {
  source = "./modules/kubernetes-auth"
  kubernetes_host = "api.ecp-silver.swisscom.com"
  kubernetes_ca_cert = var.kubernetes_ca_cert
  token_reviewer_jwt = var.token_reviewer_jwt
  k8s_path           = "ecp-silver"
}


module "ansible" {
  source = "./modules/ansible"
}


module "rootca" {
  source = "./modules/rootca"
  ca_org        = "Swisscom"
  ca_ou         = "NNI"
}


module "ecp-stage" {
  source = "./modules/int"
  vault_mount_root   = var.vault_mount_root
  pki_path           = "ecp-stage"
  server_cert_domain = "ecp-stage.ecp.sshz.pw"
  organization       = "Netset GmbH"
  ou                 = "NNI"
  cert_ttl           = "7200"
}

#
#module "safe-stage" {
#  source = "./modules/int"
#  vault_mount_root   = var.vault_mount_root
#  pki_path           = "safe-stage"
#  server_cert_domain = "safe-stage.ecp.sshz.pw"
#  organization       = "Netset GmbH"
#  ou                 = "NNI"
#}
#

#module "k8s-pki" {
#source = "./modules/cluster"
#
#  clusters = {
#    "qa-cluster" = {
#      "ca_ttl"              = 14400
#      "cert_ttl"            = 3600
#      "apiserver_hostnames" = ["node1.inovex.de", "node2.inovex.de"]
#    }
#  }
#  approle_path     = vault_auth_backend.approle.path
#  vault_mount_root = var.vault_mount_root
#  vault_address    = var.vault_address
#  organization     = "Swisscom AG"
#  ou               = "NNI"
#}
