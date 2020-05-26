# =======================================================================
# We presume Vault at https://localhost:8200
# and the presence of a ~/.vault-token here.
# -----------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------

variable "datacenter_name" {
  default = "ecp"
}

# -----------------------------------------------------------------------
# Audit Device Resources
# -----------------------------------------------------------------------

resource "vault_audit" "vaultron_audit_device" {
  type = "file"

  options = {
    file_path   = "/tmp/vault.log"
    description = "Vaultron example file audit device"
  }
}
resource "vault_auth_backend" "userpass" {
  type        = "userpass"
  path        = "userpass"
  description = "Username and password auth method"
}

resource "vault_auth_backend" "ldap" {
  type        = "ldap"
  path        = "ldap"
  description = "LDAP auth method"
}

# -----------------------------------------------------------------------
# Secrets Engines Resources
# -----------------------------------------------------------------------

resource "vault_mount" "kv" {
  path        = "kv"
  type        = "kv"
  description = "Vaultron example KV version 1 secrets engine"
}

resource "vault_mount" "kv_v2" {
  path        = "kv-v2"
  type        = "kv-v2"
  description = "KV version 2 secrets engine"
}
resource "vault_mount" "ssh_host_signer" {
  path        = "ssh-host-signer"
  type        = "ssh"
  description = "SSH Secrets Engine (host)"
}

resource "vault_mount" "ssh_client_signer" {
  path        = "ssh-client-signer"
  type        = "ssh"
  description = "SSH Secrets Engine (client)"
}

# -----------------------------------------------------------------------
# Policy Resources
# -----------------------------------------------------------------------

resource "vault_policy" "wildcard" {
  name = "wildcard"

  policy = <<EOT
// Vaultron example policy: "wildcard"
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
# Manage policies via API
path "sys/policies/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage policies via CLI
path "sys/policy/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List policies via CLI
path "sys/policy" {
  capabilities = ["read", "update", "list"]
}

# Enable and manage secrets engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List available secret engines
path "sys/mounts" {
  capabilities = [ "read" ]
}

# Create and manage entities and groups
path "identity/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage tokens
path "auth/token/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
}

resource "vault_policy" "token_admin" {
  name = "token-admin"

  policy = <<EOT
# List available auth methods
path "sys/auth" {
  capabilities = [ "read" ]
}

# Read default token configuration
path "sys/auth/token/tune" {
  capabilities = [ "read", "sudo" ]
}

# Create and manage tokens (renew, lookup, revoke, etc.)
path "auth/token/*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

# List available secrets engines
path "sys/mounts" {
  capabilities = [ "read" ]
}

# Tune the database secrets engine TTL
path "sys/mounts/database/tune" {
  capabilities = [ "update" ]
}
EOT
}

resource "vault_policy" "token_identity" {
  name = "token-identity"

  policy = <<EOT
# Configure auth methods
path "sys/auth" {
  capabilities = [ "read", "list" ]
}

# Configure auth methods
path "sys/auth/*" {
  capabilities = [ "create", "update", "read", "delete", "list", "sudo" ]
}

# Manage userpass auth methods
path "auth/userpass/*" {
  capabilities = [ "create", "read", "update", "delete" ]
}

# Manage github auth methods
path "auth/github/*" {
  capabilities = [ "create", "read", "update", "delete" ]
}

# Display the Policies tab in UI
path "sys/policies" {
  capabilities = [ "read", "list" ]
}

# Create and manage ACL policies from UI
path "sys/policies/acl/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

# Create and manage policies
path "sys/policy" {
  capabilities = [ "read", "list" ]
}

# Create and manage policies
path "sys/policy/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

# List available secret engines to retrieve accessor ID
path "sys/mounts" {
  capabilities = [ "read" ]
}

# Create and manage entities and groups
path "identity/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
EOT
}

# LDAP related policies

resource "vault_policy" "ldap_user" {
  name = "ldap-user"

  policy = <<EOT
// Vaultron example policy: "ldap-user"
path "kv/ldap-user/*" {
  capabilities = ["create", "update", "read", "list"]
}
EOT
}

resource "vault_policy" "ldap_dev" {
  name = "ldap-dev"

  policy = <<EOT
// Vaultron example policy: "ldap-dev"
path "kv/ldap-dev/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
}

# Prometheus Metrics Policy
resource "vault_policy" "prometheus" {
  name = "prometheus"

  policy = <<EOT
// Prometheus metrics gathering policy: "prometheus"
path "/sys/metrics" {
  capabilities = ["read"]
}
EOT
}
