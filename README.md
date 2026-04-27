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
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.4.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.104.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.4.0 |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | >= 0.104.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [local_file.public_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_sensitive_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [proxmox_replication.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/replication) | resource |
| [proxmox_virtual_environment_file.meta_data](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_file.network_data](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_file.user_data](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_file.vendor_data](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_vm.this](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |
| [tls_private_key.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_common_agent"></a> [common\_agent](#input\_common\_agent) | Default QEMU agent settings applied when a VM does not define agent. | <pre>object({<br/>    enabled = optional(bool)<br/>    trim    = optional(bool)<br/>    type    = optional(string)<br/>    timeout = optional(string)<br/>    wait_for_ip = optional(object({<br/>      ipv4 = optional(bool, false)<br/>      ipv6 = optional(bool, false)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_common_bios"></a> [common\_bios](#input\_common\_bios) | Default BIOS type applied when a VM does not define bios. | `string` | `null` | no |
| <a name="input_common_datastore_id"></a> [common\_datastore\_id](#input\_common\_datastore\_id) | Default datastore ID for VM disks and cloud-init. | `string` | `"local-zfs"` | no |
| <a name="input_common_disk_interface"></a> [common\_disk\_interface](#input\_common\_disk\_interface) | Default disk interface used when a disk item does not define interface. | `string` | `null` | no |
| <a name="input_common_dns"></a> [common\_dns](#input\_common\_dns) | Default DNS configuration applied to all VMs using inline initialization. | <pre>object({<br/>    domain  = optional(string)<br/>    servers = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_common_efi_disk"></a> [common\_efi\_disk](#input\_common\_efi\_disk) | Default EFI disk settings applied when a VM does not define efi\_disk. Useful with common\_bios = ovmf. | <pre>object({<br/>    datastore_id      = optional(string)<br/>    file_format       = optional(string, "raw")<br/>    type              = optional(string, "4m")<br/>    pre_enrolled_keys = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_common_network_device"></a> [common\_network\_device](#input\_common\_network\_device) | Default network device settings merged into each VM network\_devices item (unless inherit\_common is false). If a VM has no network\_devices, this becomes the single NIC. | <pre>object({<br/>    bridge       = optional(string)<br/>    model        = optional(string)<br/>    vlan_id      = optional(number)<br/>    mac_address  = optional(string)<br/>    firewall     = optional(bool)<br/>    disconnected = optional(bool)<br/>    mtu          = optional(number)<br/>    queues       = optional(number)<br/>    rate_limit   = optional(number)<br/>    trunks       = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_common_node_name"></a> [common\_node\_name](#input\_common\_node\_name) | Default Proxmox node name applied to all VMs. | `string` | `"pve"` | no |
| <a name="input_common_rng"></a> [common\_rng](#input\_common\_rng) | Default RNG device settings applied when a VM does not define rng. | <pre>object({<br/>    source    = string<br/>    max_bytes = optional(number, 1024)<br/>    period    = optional(number, 1000)<br/>  })</pre> | `null` | no |
| <a name="input_common_snippet_datastore_id"></a> [common\_snippet\_datastore\_id](#input\_common\_snippet\_datastore\_id) | Default datastore ID for cloud-init snippet files (must support snippets content type). | `string` | `"local"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Tags applied to all VMs in addition to per-VM tags. | `list(string)` | <pre>[<br/>  "terraform"<br/>]</pre> | no |
| <a name="input_local_key_directory"></a> [local\_key\_directory](#input\_local\_key\_directory) | Directory where to save SSH key files. Files will be named {vm\_name}.key and {vm\_name}.pub. | `string` | `"."` | no |
| <a name="input_save_ssh_keys_locally"></a> [save\_ssh\_keys\_locally](#input\_save\_ssh\_keys\_locally) | Whether to save generated SSH private keys to local files. | `bool` | `true` | no |
| <a name="input_vms"></a> [vms](#input\_vms) | Map of VM configurations keyed by VM name. | <pre>map(object({<br/>    # Core settings.<br/>    vm_id               = optional(number)<br/>    node_name           = optional(string)<br/>    description         = optional(string, "Managed by Terraform")<br/>    tags                = optional(list(string), [])<br/>    on_boot             = optional(bool, true)<br/>    started             = optional(bool, true)<br/>    reboot              = optional(bool, false)<br/>    pool_id             = optional(string)<br/>    scsi_hardware       = optional(string, "virtio-scsi-single")<br/>    machine             = optional(string, "q35")<br/>    bios                = optional(string)<br/>    tablet_device       = optional(bool, true)<br/>    template            = optional(bool, false)<br/>    protection          = optional(bool, false)<br/>    acpi                = optional(bool, true)<br/>    keyboard_layout     = optional(string, "en-us")<br/>    kvm_arguments       = optional(string)<br/>    migrate             = optional(bool, false)<br/>    reboot_after_update = optional(bool, true)<br/>    boot_order          = optional(list(string))<br/>    hotplug             = optional(string)<br/>    hook_script_file_id = optional(string)<br/><br/>    # Destroy behavior.<br/>    stop_on_destroy                      = optional(bool, false)<br/>    purge_on_destroy                     = optional(bool, true)<br/>    delete_unreferenced_disks_on_destroy = optional(bool, true)<br/><br/>    # Timeouts.<br/>    timeout_clone       = optional(number, 1800)<br/>    timeout_create      = optional(number, 1800)<br/>    timeout_reboot      = optional(number, 1800)<br/>    timeout_shutdown_vm = optional(number, 1800)<br/>    timeout_start_vm    = optional(number, 1800)<br/>    timeout_stop_vm     = optional(number, 300)<br/>    timeout_migrate     = optional(number, 1800)<br/><br/>    # Agent.<br/>    agent = optional(object({<br/>      enabled = optional(bool, false)<br/>      trim    = optional(bool, false)<br/>      type    = optional(string, "virtio")<br/>      timeout = optional(string, "15m")<br/>      wait_for_ip = optional(object({<br/>        ipv4 = optional(bool, false)<br/>        ipv6 = optional(bool, false)<br/>      }))<br/>    }))<br/><br/>    # CPU.<br/>    cpu = optional(object({<br/>      cores        = optional(number, 2)<br/>      sockets      = optional(number, 1)<br/>      hotplugged   = optional(number, 0)<br/>      type         = optional(string, "x86-64-v3")<br/>      architecture = optional(string, "x86_64")<br/>      flags        = optional(list(string))<br/>      units        = optional(number)<br/>      numa         = optional(bool, false)<br/>      limit        = optional(number)<br/>      affinity     = optional(string)<br/>    }))<br/><br/>    # Memory.<br/>    memory = optional(object({<br/>      dedicated      = optional(number, 4096)<br/>      floating       = optional(number, 0)<br/>      shared         = optional(number, 0)<br/>      hugepages      = optional(string)<br/>      keep_hugepages = optional(bool)<br/>    }))<br/><br/>    # Disks (list to support multiple disks).<br/>    disks = optional(list(object({<br/>      datastore_id      = optional(string)<br/>      file_id           = optional(string)<br/>      import_from       = optional(string)<br/>      interface         = optional(string)<br/>      size              = optional(number, 64)<br/>      iothread          = optional(bool, true)<br/>      discard           = optional(string, "on")<br/>      backup            = optional(bool, true)<br/>      cache             = optional(string, "none")<br/>      ssd               = optional(bool, true)<br/>      file_format       = optional(string)<br/>      aio               = optional(string)<br/>      replicate         = optional(bool, true)<br/>      serial            = optional(string)<br/>      path_in_datastore = optional(string)<br/>      speed = optional(object({<br/>        iops_read            = optional(number)<br/>        iops_read_burstable  = optional(number)<br/>        iops_write           = optional(number)<br/>        iops_write_burstable = optional(number)<br/>        read                 = optional(number)<br/>        read_burstable       = optional(number)<br/>        write                = optional(number)<br/>        write_burstable      = optional(number)<br/>      }))<br/>    })), [])<br/><br/>    # EFI disk.<br/>    efi_disk = optional(object({<br/>      datastore_id      = optional(string)<br/>      file_format       = optional(string, "raw")<br/>      type              = optional(string, "4m")<br/>      pre_enrolled_keys = optional(bool, false)<br/>    }))<br/><br/>    # TPM state.<br/>    tpm_state = optional(object({<br/>      datastore_id = optional(string)<br/>      version      = optional(string, "v2.0")<br/>    }))<br/><br/>    # CDROM. Set file_id to "none" for an empty drive.<br/>    cdrom = optional(object({<br/>      file_id   = optional(string, "cdrom")<br/>      interface = optional(string, "ide0")<br/>    }))<br/><br/>    # Network devices (list to support multiple NICs).<br/>    network_devices = optional(list(object({<br/>      bridge         = optional(string)<br/>      model          = optional(string)<br/>      vlan_id        = optional(number)<br/>      mac_address    = optional(string)<br/>      firewall       = optional(bool)<br/>      disconnected   = optional(bool)<br/>      mtu            = optional(number)<br/>      queues         = optional(number)<br/>      rate_limit     = optional(number)<br/>      trunks         = optional(string)<br/>      inherit_common = optional(bool, true)<br/>    })), [])<br/><br/>    # Host PCI passthrough (list to support multiple devices).<br/>    hostpci = optional(list(object({<br/>      device   = string<br/>      mapping  = optional(string)<br/>      id       = optional(string)<br/>      mdev     = optional(string)<br/>      rombar   = optional(bool, true)<br/>      pcie     = optional(bool, false)<br/>      xvga     = optional(bool, false)<br/>      rom_file = optional(string)<br/>    })), [])<br/><br/>    # USB passthrough.<br/>    usb = optional(list(object({<br/>      host    = optional(string)<br/>      mapping = optional(string)<br/>      usb3    = optional(bool, false)<br/>    })), [])<br/><br/>    # Operating system.<br/>    operating_system = optional(object({<br/>      type = optional(string, "l26")<br/>    }))<br/><br/>    # VGA.<br/>    vga = optional(object({<br/>      type      = optional(string, "std")<br/>      memory    = optional(number)<br/>      clipboard = optional(string)<br/>    }))<br/><br/>    # Startup behavior.<br/>    startup = optional(object({<br/>      order      = optional(number)<br/>      up_delay   = optional(number)<br/>      down_delay = optional(number)<br/>    }))<br/><br/>    # Serial devices.<br/>    serial_device = optional(object({<br/>      device = optional(string, "socket")<br/>    }))<br/><br/>    # Clone (for creating VMs from existing templates/VMs).<br/>    clone = optional(object({<br/>      vm_id        = number<br/>      datastore_id = optional(string)<br/>      node_name    = optional(string)<br/>      retries      = optional(number)<br/>      full         = optional(bool, true)<br/>    }))<br/><br/>    # Audio device.<br/>    audio_device = optional(object({<br/>      device  = optional(string, "intel-hda")<br/>      driver  = optional(string, "spice")<br/>      enabled = optional(bool, true)<br/>    }))<br/><br/>    # AMD SEV (Secure Encrypted Virtualization). Requires root@pam.<br/>    amd_sev = optional(object({<br/>      type           = optional(string, "std")<br/>      allow_smt      = optional(bool, true)<br/>      kernel_hashes  = optional(bool, false)<br/>      no_debug       = optional(bool, false)<br/>      no_key_sharing = optional(bool, false)<br/>    }))<br/><br/>    # NUMA topology (list to support multiple NUMA nodes).<br/>    numa = optional(list(object({<br/>      device    = string<br/>      cpus      = string<br/>      memory    = number<br/>      hostnodes = optional(string)<br/>      policy    = optional(string, "preferred")<br/>    })), [])<br/><br/>    # SMBIOS (System Management BIOS) settings.<br/>    smbios = optional(object({<br/>      family       = optional(string)<br/>      manufacturer = optional(string)<br/>      product      = optional(string)<br/>      serial       = optional(string)<br/>      sku          = optional(string)<br/>      uuid         = optional(string)<br/>      version      = optional(string)<br/>    }))<br/><br/>    # Random number generator. Requires root@pam.<br/>    rng = optional(object({<br/>      source    = string<br/>      max_bytes = optional(number, 1024)<br/>      period    = optional(number, 1000)<br/>    }))<br/><br/>    # Watchdog device.<br/>    watchdog = optional(object({<br/>      enabled = optional(bool, false)<br/>      model   = optional(string, "i6300esb")<br/>      action  = optional(string, "none")<br/>    }))<br/><br/>    # VirtioFS shared directories (list to support multiple mounts).<br/>    virtiofs = optional(list(object({<br/>      mapping      = string<br/>      cache        = optional(string)<br/>      direct_io    = optional(bool)<br/>      expose_acl   = optional(bool)<br/>      expose_xattr = optional(bool)<br/>    })), [])<br/><br/>    # Replication job (proxmox_replication).<br/>    replication = optional(object({<br/>      target   = string<br/>      type     = optional(string, "local")<br/>      schedule = optional(string, "*/15")<br/>      rate     = optional(number)<br/>      comment  = optional(string)<br/>      disable  = optional(bool, false)<br/>    }))<br/><br/>    # SSH key generation. Set to {} to generate a key pair with defaults. Auto-injects public key into initialization.user_account.keys.<br/>    ssh_key = optional(object({<br/>      enabled     = optional(bool, true)<br/>      algorithm   = optional(string, "ED25519")<br/>      rsa_bits    = optional(number, 4096)<br/>      ecdsa_curve = optional(string, "P384")<br/>    }))<br/><br/>    # Cloud-init / Initialization.<br/>    initialization = optional(object({<br/>      datastore_id = optional(string)<br/>      interface    = optional(string)<br/>      file_format  = optional(string)<br/>      upgrade      = optional(bool)<br/><br/>      # Inline DNS configuration.<br/>      dns = optional(object({<br/>        domain  = optional(string)<br/>        servers = optional(list(string))<br/>      }))<br/><br/>      # Inline IP configurations (supports multiple for multi-NIC).<br/>      ip_config = optional(list(object({<br/>        ipv4 = optional(object({<br/>          address = optional(string, "dhcp")<br/>          gateway = optional(string)<br/>        }))<br/>        ipv6 = optional(object({<br/>          address = optional(string)<br/>          gateway = optional(string)<br/>        }))<br/>      })), [])<br/><br/>      # Inline user account.<br/>      user_account = optional(object({<br/>        username = optional(string)<br/>        password = optional(string)<br/>        keys     = optional(list(string), [])<br/>      }))<br/><br/>      # File-based cloud-init: path to local YAML files (read with file()).<br/>      user_data_file    = optional(string)<br/>      network_data_file = optional(string)<br/>      vendor_data_file  = optional(string)<br/>      meta_data_file    = optional(string)<br/><br/>      # Content-based cloud-init: raw string content (use with templatefile()).<br/>      # Takes precedence over the corresponding *_file variable.<br/>      user_data_content    = optional(string)<br/>      network_data_content = optional(string)<br/>      meta_data_content    = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ssh_private_key_file_paths"></a> [ssh\_private\_key\_file\_paths](#output\_ssh\_private\_key\_file\_paths) | Map of VM names to their saved private key file paths. |
| <a name="output_ssh_private_keys"></a> [ssh\_private\_keys](#output\_ssh\_private\_keys) | Map of VM names to their generated SSH private keys in PEM format. |
| <a name="output_ssh_public_keys"></a> [ssh\_public\_keys](#output\_ssh\_public\_keys) | Map of VM names to their generated SSH public keys in OpenSSH format. |
| <a name="output_vm_ids"></a> [vm\_ids](#output\_vm\_ids) | Map of VM names to their Proxmox VM IDs. |
| <a name="output_vm_ipv4_addresses"></a> [vm\_ipv4\_addresses](#output\_vm\_ipv4\_addresses) | Map of VM names to their IPv4 addresses (list of lists, per interface). |
| <a name="output_vm_ipv6_addresses"></a> [vm\_ipv6\_addresses](#output\_vm\_ipv6\_addresses) | Map of VM names to their IPv6 addresses (list of lists, per interface). |
| <a name="output_vm_mac_addresses"></a> [vm\_mac\_addresses](#output\_vm\_mac\_addresses) | Map of VM names to their MAC addresses. |
| <a name="output_vms"></a> [vms](#output\_vms) | Map of VM resources with selected attributes (id, vm\_id, name, node\_name, tags, IPs, MACs). |
| <a name="output_vms_by_node"></a> [vms\_by\_node](#output\_vms\_by\_node) | Map of node names to lists of VM IDs on that node. |
| <a name="output_vms_by_tag"></a> [vms\_by\_tag](#output\_vms\_by\_tag) | Map of tags to lists of VM IDs with that tag. |
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
