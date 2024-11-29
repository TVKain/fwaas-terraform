# Number of VLAN networks to create
variable "number_of_vlans" {
  type        = number
  default     = 3
  description = "The number of VLAN networks to create."
}

# External network for each VLAN network
variable "external_network" {
  type        = string
  default     = "external-net"
  description = "The external network for the VLAN networks."
}

# Number of VLAN networks to create
variable "number_of_rules" {
  type        = number
  default     = 5
  description = "The number of Firewall Rules for each VLAN to create."
}

# Admin user id 
variable "admin_user" {
  type = string 
  description = "ID of admin user"
}

# Admin role id 
variable "admin_role" {
  type = string 
  description = "ID of admin role"
}