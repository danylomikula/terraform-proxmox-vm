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

# VM with file-based cloud-init YAML snippets.
# The module uploads the YAML files as Proxmox snippets automatically.
module "vm" {
  source = "../.."

  common_node_name            = "pve"
  common_datastore_id         = "local-zfs"
  common_snippet_datastore_id = "local"
  common_network_device = {
    bridge = "vmbr2"
    model  = "virtio"
  }

  vms = {
    docker-01 = {
      # Generate SSH key pair. The public key replaces {{ssh_public_key}} in user-data.
      ssh_key = {
        enabled   = true
        algorithm = "ED25519"
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
    }
  }
}

output "vm_ids" {
  value = module.vm.vm_ids
}

output "vm_ipv4" {
  value = module.vm.vm_ipv4_addresses
}

output "ssh_key_files" {
  value = module.vm.ssh_private_key_file_paths
}
