terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.105.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}

# Download Rocky Linux 10 cloud image.
module "images" {
  source  = "danylomikula/download-file/proxmox"
  version = "1.0.0"

  common_node_name    = "pve"
  common_datastore_id = "local"

  files = {
    rocky-10-cloud = {
      url          = "https://dl.rockylinux.org/pub/rocky/10/images/x86_64/Rocky-10-GenericCloud-Base.latest.x86_64.qcow2"
      content_type = "import"
      file_name    = "rocky-10-generic-cloud-base.qcow2"
    }
  }
}

# VM with inline cloud-init and SSH key generation.
module "vm" {
  source = "../.."

  common_node_name    = "pve"
  common_datastore_id = "local-zfs"

  common_dns = {
    domain  = "lab.local"
    servers = ["1.1.1.1", "8.8.8.8"]
  }

  vms = {
    docker-01 = {
      # Generate SSH key pair and auto-inject into cloud-init.
      ssh_key = {
        enabled = true
      }

      cpu = {
        cores = 4
      }

      memory = {
        dedicated = 8192
      }

      disks = [{
        interface   = "scsi0"
        size        = 64
        import_from = module.images.file_ids["rocky-10-cloud"]
      }]

      network_devices = [{
        bridge  = "vmbr2"
        model   = "virtio"
        vlan_id = 20
      }]

      agent = {
        enabled = true
      }

      initialization = {
        ip_config = [{
          ipv4 = {
            address = "10.20.0.20/16"
            gateway = "10.20.0.1"
          }
        }]

        user_account = {
          username = "admin"
        }
      }

      tags = ["docker"]
    }
  }
}
