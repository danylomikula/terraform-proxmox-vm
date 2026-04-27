terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.104.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}

# Existing Ubuntu installer ISO in Proxmox storage.
data "proxmox_file" "ubuntu_iso" {
  node_name    = "pve"
  datastore_id = "local"
  content_type = "iso"
  file_name    = "ubuntu-24.04.4-live-server-amd64.iso"
}

# Basic single VM that boots Ubuntu installer from CD-ROM.
module "vm" {
  source = "../.."

  common_node_name = "pve"

  vms = {
    web-01 = {
      disks = [{
        datastore_id = "local-zfs"
        interface    = "scsi0"
        size         = 32
      }]

      cdrom = {
        file_id   = data.proxmox_file.ubuntu_iso.id
        interface = "ide0"
      }

      # Boot from installer ISO first.
      boot_order = ["ide0", "scsi0", "net0"]

      network_devices = [{
        bridge = "vmbr0"
      }]
    }
  }
}
