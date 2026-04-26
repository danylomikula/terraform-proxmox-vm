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

# Download cloud image.
module "images" {
  source  = "danylomikula/download-file/proxmox"
  version = "1.0.0"

  common_node_name    = "pve"
  common_datastore_id = "local"

  files = {
    ubuntu-cloud = {
      url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      content_type = "import"
      file_name    = "ubuntu-24.04-cloudimg-amd64.qcow2"
    }
  }
}

# Create VMs with full configuration.
module "vms" {
  source = "../.."

  common_node_name    = "pve"
  common_datastore_id = "local-lvm"
  common_tags         = ["terraform", "ubuntu"]

  common_dns = {
    domain  = "lab.local"
    servers = ["1.1.1.1", "8.8.8.8"]
  }

  common_network_device = {
    bridge = "vmbr0"
  }

  local_key_directory = path.module

  vms = {
    # UEFI VM with EFI disk, cloud image, and SSH key generation.
    k8s-master = {
      bios = "ovmf"

      cpu = {
        cores = 4
        type  = "x86-64-v3"
      }

      memory = {
        dedicated = 8192
      }

      ssh_key = {
        enabled = true
      }

      efi_disk = {}

      disks = [
        {
          interface   = "scsi0"
          size        = 64
          import_from = module.images.file_ids["ubuntu-cloud"]
        },
        {
          interface = "scsi1"
          size      = 128
        },
      ]

      network_devices = [
        {
          bridge = "vmbr0"
        },
        {
          bridge  = "vmbr1"
          vlan_id = 100
        },
      ]

      agent = {
        enabled = true
      }

      operating_system = {
        type = "l26"
      }

      serial_device = {
        device = "socket"
      }

      initialization = {
        ip_config = [
          {
            ipv4 = {
              address = "10.0.0.100/24"
              gateway = "10.0.0.1"
            }
          },
          {
            ipv4 = {
              address = "10.0.1.100/24"
            }
          },
        ]

        user_account = {
          username = "admin"
        }
      }

      tags = ["kubernetes", "master"]
    }

    # Worker node with simpler config, inheriting common_network_device.
    k8s-worker-01 = {
      cpu = {
        cores = 2
      }

      memory = {
        dedicated = 4096
      }

      ssh_key = {
        enabled = true
      }

      disks = [{
        interface   = "scsi0"
        size        = 32
        import_from = module.images.file_ids["ubuntu-cloud"]
      }]

      agent = {
        enabled = true
      }

      initialization = {
        ip_config = [{
          ipv4 = {
            address = "10.0.0.101/24"
            gateway = "10.0.0.1"
          }
        }]

        user_account = {
          username = "admin"
        }
      }

      tags = ["kubernetes", "worker"]
    }
  }
}

output "vm_ids" {
  value = module.vms.vm_ids
}

output "vm_ipv4" {
  value = module.vms.vm_ipv4_addresses
}

output "vms_by_node" {
  value = module.vms.vms_by_node
}

output "vms_by_tag" {
  value = module.vms.vms_by_tag
}

output "ssh_key_files" {
  value = module.vms.ssh_private_key_file_paths
}

output "ssh_connection_commands" {
  description = "SSH connection commands for each VM."
  value = {
    for name, path in module.vms.ssh_private_key_file_paths :
    name => "ssh -i ${path} admin@<ip>"
  }
}

output "downloaded_images" {
  value = module.images.file_ids
}
