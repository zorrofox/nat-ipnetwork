
variable user {
  default = "<Your OPC Account>"
}
variable password {
  default = "<Your OPC Password>"
}
variable domain {
  default = "<Your OPC Domain>"
}
variable endpoint {
  default = "<OPC Endpoint for Your IDC>"
}

variable ssh_user {
  description = "User account for ssh access to the image"
  default     = "opc"
}

variable ssh_public_key {
  description = "File location of the ssh public key"
  default     = "<Path of the Public Key File in Your Computer>"
}
