# variables.tf
# Defines all input variables for the multicast IPTV lab
# Actual values go in terraform.tfvars (never committed to GitHub)

variable "proxmox_endpoint" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://192.168.10.10:8006"
}

variable "proxmox_username" {
  description = "Proxmox login user"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox root password"
  type        = string
  sensitive   = true  # hides value from terminal output
}

variable "proxmox_node" {
  description = "Your Proxmox node name"
  type        = string
  default     = "chiiiworld"
}

variable "lxc_template" {
  description = "Debian LXC template to build containers from"
  type        = string
  default     = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
}

variable "storage_pool" {
  description = "Proxmox storage pool for LXC disks"
  type        = string
  default     = "local-lvm"
}

variable "vlan70_gateway" {
  description = "FortiGate VLAN 70 gateway IP"
  type        = string
  default     = "192.168.70.1"
}

variable "ssh_public_key" {
  description = "Your SSH public key for accessing the LXCs"
  type        = string
}

variable "root_password" {
  description = "Root password for the LXC containers"
  type        = string
  sensitive   = true
}