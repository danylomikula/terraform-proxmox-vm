# Proxmox VM Terraform Module

[![Release](https://img.shields.io/github/v/release/danylomikula/terraform-proxmox-vm)](https://github.com/danylomikula/terraform-proxmox-vm/releases)
[![Pre-Commit](https://github.com/danylomikula/terraform-proxmox-vm/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/danylomikula/terraform-proxmox-vm/actions/workflows/pre-commit.yml)
[![License](https://img.shields.io/github/license/danylomikula/terraform-proxmox-vm)](https://github.com/danylomikula/terraform-proxmox-vm/blob/main/LICENSE)

Terraform module for managing Proxmox VE virtual machines with broad `bpg/proxmox` provider coverage including cloud-init, SSH key generation, cloning, PCI/USB passthrough, and advanced VM configuration options.

## Features

- Manage multiple VMs from a single module call via map-based `for_each`
- Cloud-init in three modes: inline (`user_account`), file-based (`*_file`), and content-based (`*_content` with `templatefile()`)
- Automatic TLS key pair generation with public key auto-injection into cloud-init
- Clone VMs from existing templates (full or linked)
- PCI and USB device passthrough
- Shared `common_*` defaults (node, datastore, tags, DNS, BIOS/EFI, agent, RNG, disk interface, network device) merged with per-VM overrides
- NIC inheritance with explicit `inherit_common = false` opt-out per device
- Advanced hardware: EFI disk, TPM, NUMA, AMD SEV, VirtioFS, watchdog, audio device, SMBIOS, serial device
- Rich outputs grouped by node and tag, with IPv4/IPv6 and MAC address maps

## Quick Start

```hcl
module "vm" {
  source  = "danylomikula/vm/proxmox"
  version = "~> 1.0"

  common_node_name = "pve"

  vms = {
    web-01 = {
      disks = [{
        interface = "scsi0"
        size      = 32
      }]

      network_devices = [{
        bridge = "vmbr0"
      }]
    }
  }
}
```

## Usage with Download File Module

```hcl
module "images" {
  source  = "danylomikula/download-file/proxmox"
  version = "~> 1.0"

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

module "vm" {
  source  = "danylomikula/vm/proxmox"
  version = "~> 1.0"

  common_node_name    = "pve"
  common_datastore_id = "local-lvm"
  common_tags         = ["terraform", "ubuntu"]

  vms = {
    app-01 = {
      cpu = {
        cores = 4
      }

      memory = {
        dedicated = 8192
      }

      disks = [{
        interface   = "scsi0"
        size        = 64
        import_from = module.images.file_ids["ubuntu-cloud"]
      }]

      network_devices = [{
        bridge = "vmbr0"
      }]

      agent = {
        enabled = true
      }

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
```

## VM Examples

### Clone from Template

```hcl
module "vm" {
  source  = "danylomikula/vm/proxmox"
  version = "~> 1.0"

  vms = {
    app-01 = {
      clone = {
        vm_id = 9000
        full  = true
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
```

### Cloud-Init with SSH Key Generation

```hcl
module "vm" {
  source  = "danylomikula/vm/proxmox"
  version = "~> 1.0"

  common_node_name = "pve"
  common_dns = {
    domain  = "lab.local"
    servers = ["1.1.1.1", "8.8.8.8"]
  }

  vms = {
    docker-01 = {
      ssh_key = {
        enabled   = true
        algorithm = "ED25519"
      }

      disks = [{
        interface = "scsi0"
        size      = 64
      }]

      network_devices = [{
        bridge = "vmbr0"
      }]

      initialization = {
        ip_config = [{
          ipv4 = {
            address = "10.0.0.20/24"
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
```

### Cloud-Init with File-Based Snippets

```hcl
module "vm" {
  source  = "danylomikula/vm/proxmox"
  version = "~> 1.0"

  common_node_name            = "pve"
  common_snippet_datastore_id = "local"

  vms = {
    docker-01 = {
      ssh_key = {
        enabled = true
      }

      disks = [{
        interface = "scsi0"
        size      = 64
      }]

      network_devices = [{
        bridge = "vmbr0"
      }]

      initialization = {
        # The module uploads YAML files as Proxmox snippets automatically.
        # `{{ssh_public_key}}` placeholder in user-data is replaced with the generated key.
        user_data_file    = "${path.module}/cloud-init/docker-01/user-data.yml"
        network_data_file = "${path.module}/cloud-init/docker-01/network-data.yml"
        meta_data_file    = "${path.module}/cloud-init/docker-01/meta-data.yml"
      }
    }
  }
}
```

Example `user-data.yml`:

```yaml
#cloud-config
users:
  - name: admin
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - {{ssh_public_key}}

packages:
  - qemu-guest-agent

runcmd:
  - systemctl enable --now qemu-guest-agent
```

### Cloud-Init with `templatefile()`

For shared templates with per-VM variables, use `*_content` options.

```hcl
module "vm" {
  source  = "danylomikula/vm/proxmox"
  version = "~> 1.0"

  common_snippet_datastore_id = "local"

  vms = {
    docker-01 = {
      disks = [{
        interface = "scsi0"
        size      = 64
      }]

      network_devices = [{
        bridge = "vmbr0"
      }]

      initialization = {
        user_data_content = templatefile("${path.module}/cloud-init/user-data.yml.tpl", {
          username = "admin"
          ssh_keys = ["ssh-ed25519 AAAA..."]
        })

        meta_data_content = templatefile("${path.module}/cloud-init/meta-data.yml.tpl", {
          hostname = "docker-01"
        })
      }
    }
  }
}
```

### Shared NIC Defaults with Per-VM Override

```hcl
module "vm" {
  source  = "danylomikula/vm/proxmox"
  version = "~> 1.0"

  common_network_device = {
    bridge = "vmbr2"
    model  = "virtio"
  }

  vms = {
    app-01 = {
      # Inherits bridge/model, overrides only VLAN.
      network_devices = [{
        vlan_id = 20
      }]
    }

    storage-01 = {
      # This NIC does not inherit common_network_device.
      network_devices = [{
        bridge         = "vmbr-storage"
        inherit_common = false
      }]
    }
  }
}
```

### Common Defaults (BIOS, EFI, Agent, RNG)

```hcl
module "vm" {
  source  = "danylomikula/vm/proxmox"
  version = "~> 1.0"

  common_bios = "ovmf"
  common_efi_disk = {
    type = "4m"
  }

  common_agent = {
    enabled = true
  }

  common_rng = {
    source = "/dev/urandom"
  }

  common_disk_interface = "scsi0"

  vms = {
    app-01 = {
      # Inherits all common defaults.
      disks = [{
        size = 32
      }]
    }

    app-02 = {
      # VM-level value overrides common default.
      bios = "seabios"

      agent = {
        enabled = false
      }

      disks = [{
        size = 64
      }]
    }
  }
}
```

### Boot from Installer ISO

```hcl
data "proxmox_file" "ubuntu_iso" {
  node_name    = "pve"
  datastore_id = "local"
  content_type = "iso"
  file_name    = "ubuntu-24.04.4-live-server-amd64.iso"
}

module "vm" {
  source  = "danylomikula/vm/proxmox"
  version = "~> 1.0"

  common_node_name = "pve"

  vms = {
    web-01 = {
      disks = [{
        interface = "scsi0"
        size      = 32
      }]

      cdrom = {
        file_id   = data.proxmox_file.ubuntu_iso.id
        interface = "ide0"
      }

      boot_order = ["ide0", "scsi0", "net0"]

      network_devices = [{
        bridge = "vmbr0"
      }]
    }
  }
}
```

## Cloud-Init Modes

The module supports three mutually-compatible cloud-init configuration styles:

- **Inline** — set `initialization.user_account`, `initialization.dns`, `initialization.ip_config`. Provider generates cloud-init data automatically. Best for simple VM provisioning.
- **File-based** — set `initialization.user_data_file`, `network_data_file`, `meta_data_file`, or `vendor_data_file`. The module uploads YAML files as Proxmox snippets. Best for full control over cloud-init.
- **Content-based** — set `initialization.user_data_content`, `network_data_content`, or `meta_data_content`. Useful with `templatefile()` for per-VM variable injection. `*_content` takes precedence over the corresponding `*_file`.

`initialization.user_account` is mutually exclusive with `user_data_file` / `user_data_content` (validated). For predictable hostname override, set `local-hostname` via `meta_data_file` or `meta_data_content` — works in all three modes.

## How `ssh_key` Works

When `ssh_key.enabled = true` (or `ssh_key = {}` to use defaults), the module generates a TLS key pair and injects the public key into cloud-init:

- **Inline mode** — public key is appended to `initialization.user_account.keys`.
- **File/content mode** — the module replaces `{{ssh_public_key}}` placeholder in user-data with the generated key. If the placeholder is missing, no key is injected into that body.

Generated keys are exposed via `ssh_public_keys` and `ssh_private_keys` outputs and can be saved locally with `save_ssh_keys_locally = true` and `local_key_directory`.

## Important Notes

- For snippet uploads (`user_data_file`, `*_content`, etc.), the Proxmox provider must be configured with SSH access to the target node, and the snippet datastore must allow content type `snippets`.
- The module uses `lifecycle.ignore_changes = [initialization]` to prevent recreation when cloud-init data changes after first boot.
- `import_from` requires the source image to exist when the VM is created. See [Safe Image Cleanup](#safe-image-cleanup) for safely removing source images afterward.
- All `common_*` variables are merged with per-VM values; per-VM values always take precedence.
- `network_devices` items inherit `common_network_device` defaults unless `inherit_common = false`.

## Safe Image Cleanup

When a VM is created from `disk.import_from` using an image managed by a separate `download-file` module, remove the source image in two Terraform applies to avoid touching the running VM.

1. Decouple the VM disk from the image module output:
   - Change `import_from` from `module.images.file_ids["rocky-cloud"]` to a literal file ID like `local:import/rocky-10-generic-cloud-base.qcow2`.
   - Run `terraform apply`.

2. Remove the image from the download module:
   - Remove the image entry from the `files` map.
   - Run `terraform apply` again.

The VM disk is decoupled from the image after first boot — Terraform destroys only the `proxmox_virtual_environment_download_file` resource.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Related Modules

| Module | Description | GitHub | Terraform Registry |
|--------|-------------|--------|--------------------|
| **terraform-proxmox-download-file** | Download ISO, cloud images, container templates, OCI images to Proxmox storage | [GitHub](https://github.com/danylomikula/terraform-proxmox-download-file) | [Registry](https://registry.terraform.io/modules/danylomikula/download-file/proxmox) |

## Authors

Module managed by [Danylo Mikula](https://github.com/danylomikula).

## Contributing

Contributions are welcome! Please read the [Contributing Guide](.github/contributing.md) for details on the process and commit conventions.

## License

Apache 2.0 Licensed. See [LICENSE](LICENSE) for full details.
