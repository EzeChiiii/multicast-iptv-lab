terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = true
}

resource "proxmox_virtual_environment_container" "endpoint" {
  count       = 3
  node_name   = var.proxmox_node
  description = "Multicast IPTV Endpoint - Channel ${count.index + 1}"

  vm_id    = 300 + count.index + 1





operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 1024
  }

  disk {
    datastore_id = var.storage_pool
    size         = 4
  }

  network_interface {
    name    = "eth0"
    bridge  = "vmbr0"
    vlan_id = 70
  }

  initialization {
      hostname = "iptv-endpoint-${count.index + 1}"
    ip_config {
      ipv4 {
        address = "192.168.70.${count.index + 11}/24"
        gateway = var.vlan70_gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.root_password
    }
  }

  started      = true
  unprivileged = true

  features {
    nesting = true
  }
}

resource "proxmox_virtual_environment_container" "streamer" {
  node_name   = var.proxmox_node
  description = "Multicast IPTV Streamer - FFmpeg Headend"

  vm_id = 300

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 4096
    swap      = 512
  }

  disk {
    datastore_id = var.storage_pool
    size         = 10
  }

  network_interface {
    name    = "eth0"
    bridge  = "vmbr0"
    vlan_id = 70
  }

  initialization {
    hostname = "iptv-streamer"

    ip_config {
      ipv4 {
        address = "192.168.70.10/24"
        gateway = var.vlan70_gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.root_password
    }
  }

  started      = true
  unprivileged = true

  features {
    nesting = true
  }
}

resource "proxmox_virtual_environment_vm" "desktop" {
  node_name   = var.proxmox_node
  vm_id       = 304
  name        = "iptv-desktop"
  description = "Ubuntu Desktop VM for IPTV stream playback"

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = var.storage_pool
    file_id      = "local:iso/ubuntu-24.04.4-desktop-amd64.iso"
    interface    = "ide2"
    file_format  = "raw"
  }

  disk {
    datastore_id = var.storage_pool
    interface    = "virtio0"
    size         = 32
    file_format  = "raw"
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = 70
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.70.20/24"
        gateway = var.vlan70_gateway
      }
    }

    user_account {
      username = "iptv"
      password = var.root_password
      keys     = [var.ssh_public_key]
    }
  }

  operating_system {
    type = "l26"
  }

  vga {
    type = "virtio"
  }

  started = true
}