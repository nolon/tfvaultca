resource "vault_policy" "sign-ssh" {
  name = "sign-ssh"

  policy = <<EOT
path "ssh-host-signer/roles/ansible"
 {
  capabilities = ["create", "update"]
}
path "ssh-client-signer/roles/ansible"
 {
  capabilities = ["create", "update"]
}
path "kv/*"
 {
  capabilities = ["read"]
}
EOT
}

resource "vault_token_auth_backend_role" "sign-ssh" {
  role_name = "sign-ssh"
  allowed_policies    = [vault_policy.sign-ssh.name]
  token_policies    = [vault_policy.sign-ssh.name]
}


