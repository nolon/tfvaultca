variable server_cert_domain {
    description = "We create a role to create client certs, what DNS domain will these certs be in"
    default = "sshz.pw"
}

variable ca_org {
    description = "We create a role to create client certs, what DNS domain will these certs be in"
    default = "Netset GmbH"
}

variable ca_ou {
    description = "We create a role to create client certs, what DNS domain will these certs be in"
    default = "Netset GmbH"
}
