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

# Clone VMs from an existing template.
module "vm" {
  source = "../.."

  common_node_name = "pve"
  common_tags      = ["terraform", "cloned"]

  vms = {
    app-01 = {
      clone = {
        vm_id = var.template_vm_id
        full  = true
      }

      cpu = {
        cores = 2
      }

      memory = {
        dedicated = 4096
      }

      network_devices = [{
        bridge = "vmbr0"
      }]

      initialization = {
        ip_config = [{
          ipv4 = {
            address = "10.0.0.10/24"
            gateway = "10.0.0.1"
          }
        }]

        user_account = {
          username = "admin"
        }
      }
    }
  }
}
