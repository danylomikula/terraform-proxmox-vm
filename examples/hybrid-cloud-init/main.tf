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

# Download cloud image.
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

# Hybrid cloud-init usage:
# - docker-01 uses file-based cloud-init snippets
# - docker-02 uses inline user/network plus meta-data hostname override
module "vm" {
  source = "../.."

  common_node_name            = "pve"
  common_datastore_id         = "local-lvm"
  common_snippet_datastore_id = "local"
  common_network_device = {
    bridge = "vmbr2"
    model  = "virtio"
  }

  local_key_directory = path.module

  vms = {
    docker-01 = {
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

      # Inherits bridge/model from common_network_device, overrides only VLAN.
      network_devices = [{
        vlan_id = 20
      }]

      agent = {
        enabled = true
      }

      rng = {
        source = "/dev/urandom"
      }

      initialization = {
        user_data_file    = "${path.module}/cloud-init/docker-01/user-data.yml"
        network_data_file = "${path.module}/cloud-init/docker-01/network-data.yml"
        meta_data_file    = "${path.module}/cloud-init/docker-01/meta-data.yml"
      }

      tags = ["docker", "file-cloudinit"]
    }

    docker-02 = {
      ssh_key = {
        enabled = true
      }

      cpu = {
        cores = 2
      }

      memory = {
        dedicated = 4096
      }

      disks = [{
        interface   = "scsi0"
        size        = 32
        import_from = module.images.file_ids["rocky-10-cloud"]
      }]

      # Inherits bridge/model from common_network_device, overrides only VLAN.
      network_devices = [{
        vlan_id = 30
      }]

      agent = {
        enabled = true
      }

      rng = {
        source = "/dev/urandom"
      }

      initialization = {
        dns = {
          domain  = "lab.local"
          servers = ["1.1.1.1", "8.8.8.8"]
        }

        ip_config = [{
          ipv4 = {
            address = "10.30.55.179/16"
            gateway = "10.30.0.1"
          }
        }]

        user_account = {
          username = "admin"
          password = "admin"
        }

        # For predictable hostname override, set local-hostname in meta-data.
        meta_data_file = "${path.module}/cloud-init/docker-02/meta-data.yml"
      }

      tags = ["docker", "inline-cloudinit"]
    }
  }
}
