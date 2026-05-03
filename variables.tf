variable "vms" {
  description = "Map of VM configurations keyed by VM name."
  type = map(object({
    # Core settings.
    vm_id               = optional(number)
    node_name           = optional(string)
    description         = optional(string, "Managed by Terraform")
    tags                = optional(list(string), [])
    on_boot             = optional(bool, true)
    started             = optional(bool, true)
    reboot              = optional(bool, false)
    pool_id             = optional(string)
    scsi_hardware       = optional(string, "virtio-scsi-single")
    machine             = optional(string, "q35")
    bios                = optional(string)
    tablet_device       = optional(bool, true)
    template            = optional(bool, false)
    protection          = optional(bool, false)
    acpi                = optional(bool, true)
    keyboard_layout     = optional(string, "en-us")
    kvm_arguments       = optional(string)
    migrate             = optional(bool, false)
    reboot_after_update = optional(bool, true)
    boot_order          = optional(list(string))
    hotplug             = optional(string)
    hook_script_file_id = optional(string)

    # Destroy behavior.
    stop_on_destroy                      = optional(bool, false)
    purge_on_destroy                     = optional(bool, true)
    delete_unreferenced_disks_on_destroy = optional(bool, true)

    # Timeouts.
    timeout_clone       = optional(number, 1800)
    timeout_create      = optional(number, 1800)
    timeout_reboot      = optional(number, 1800)
    timeout_shutdown_vm = optional(number, 1800)
    timeout_start_vm    = optional(number, 1800)
    timeout_stop_vm     = optional(number, 300)
    timeout_migrate     = optional(number, 1800)

    # Agent.
    agent = optional(object({
      enabled = optional(bool, false)
      trim    = optional(bool, false)
      type    = optional(string, "virtio")
      timeout = optional(string, "15m")
      wait_for_ip = optional(object({
        ipv4 = optional(bool, false)
        ipv6 = optional(bool, false)
      }))
    }))

    # CPU.
    cpu = optional(object({
      cores        = optional(number, 2)
      sockets      = optional(number, 1)
      hotplugged   = optional(number, 0)
      type         = optional(string, "x86-64-v3")
      architecture = optional(string, "x86_64")
      flags        = optional(list(string))
      units        = optional(number)
      numa         = optional(bool, false)
      limit        = optional(number)
      affinity     = optional(string)
    }))

    # Memory.
    memory = optional(object({
      dedicated      = optional(number, 4096)
      floating       = optional(number, 0)
      shared         = optional(number, 0)
      hugepages      = optional(string)
      keep_hugepages = optional(bool)
    }))

    # Disks (list to support multiple disks).
    disks = optional(list(object({
      datastore_id      = optional(string)
      file_id           = optional(string)
      import_from       = optional(string)
      interface         = optional(string)
      size              = optional(number, 64)
      iothread          = optional(bool, true)
      discard           = optional(string, "on")
      backup            = optional(bool, true)
      cache             = optional(string, "none")
      ssd               = optional(bool, true)
      file_format       = optional(string)
      aio               = optional(string)
      replicate         = optional(bool, true)
      serial            = optional(string)
      path_in_datastore = optional(string)
      speed = optional(object({
        iops_read            = optional(number)
        iops_read_burstable  = optional(number)
        iops_write           = optional(number)
        iops_write_burstable = optional(number)
        read                 = optional(number)
        read_burstable       = optional(number)
        write                = optional(number)
        write_burstable      = optional(number)
      }))
    })), [])

    # EFI disk.
    efi_disk = optional(object({
      datastore_id      = optional(string)
      file_format       = optional(string, "raw")
      type              = optional(string, "4m")
      pre_enrolled_keys = optional(bool, false)
    }))

    # TPM state.
    tpm_state = optional(object({
      datastore_id = optional(string)
      version      = optional(string, "v2.0")
    }))

    # CDROM. Set file_id to "none" for an empty drive.
    cdrom = optional(object({
      file_id   = optional(string, "cdrom")
      interface = optional(string, "ide0")
    }))

    # Network devices (list to support multiple NICs).
    network_devices = optional(list(object({
      bridge         = optional(string)
      model          = optional(string)
      vlan_id        = optional(number)
      mac_address    = optional(string)
      firewall       = optional(bool)
      disconnected   = optional(bool)
      mtu            = optional(number)
      queues         = optional(number)
      rate_limit     = optional(number)
      trunks         = optional(string)
      inherit_common = optional(bool, true)
    })), [])

    # Host PCI passthrough (list to support multiple devices).
    hostpci = optional(list(object({
      device   = string
      mapping  = optional(string)
      id       = optional(string)
      mdev     = optional(string)
      rombar   = optional(bool, true)
      pcie     = optional(bool, false)
      xvga     = optional(bool, false)
      rom_file = optional(string)
    })), [])

    # USB passthrough.
    usb = optional(list(object({
      host    = optional(string)
      mapping = optional(string)
      usb3    = optional(bool, false)
    })), [])

    # Operating system.
    operating_system = optional(object({
      type = optional(string, "l26")
    }))

    # VGA.
    vga = optional(object({
      type      = optional(string, "std")
      memory    = optional(number)
      clipboard = optional(string)
    }))

    # Startup behavior.
    startup = optional(object({
      order      = optional(number)
      up_delay   = optional(number)
      down_delay = optional(number)
    }))

    # Serial devices.
    serial_device = optional(object({
      device = optional(string, "socket")
    }))

    # Clone (for creating VMs from existing templates/VMs).
    clone = optional(object({
      vm_id        = number
      datastore_id = optional(string)
      node_name    = optional(string)
      retries      = optional(number)
      full         = optional(bool, true)
    }))

    # Audio device.
    audio_device = optional(object({
      device  = optional(string, "intel-hda")
      driver  = optional(string, "spice")
      enabled = optional(bool, true)
    }))

    # AMD SEV (Secure Encrypted Virtualization). Requires root@pam.
    amd_sev = optional(object({
      type           = optional(string, "std")
      allow_smt      = optional(bool, true)
      kernel_hashes  = optional(bool, false)
      no_debug       = optional(bool, false)
      no_key_sharing = optional(bool, false)
    }))

    # NUMA topology (list to support multiple NUMA nodes).
    numa = optional(list(object({
      device    = string
      cpus      = string
      memory    = number
      hostnodes = optional(string)
      policy    = optional(string, "preferred")
    })), [])

    # SMBIOS (System Management BIOS) settings.
    smbios = optional(object({
      family       = optional(string)
      manufacturer = optional(string)
      product      = optional(string)
      serial       = optional(string)
      sku          = optional(string)
      uuid         = optional(string)
      version      = optional(string)
    }))

    # Random number generator. Requires root@pam.
    rng = optional(object({
      source    = string
      max_bytes = optional(number, 1024)
      period    = optional(number, 1000)
    }))

    # Watchdog device.
    watchdog = optional(object({
      enabled = optional(bool, false)
      model   = optional(string, "i6300esb")
      action  = optional(string, "none")
    }))

    # VirtioFS shared directories (list to support multiple mounts).
    virtiofs = optional(list(object({
      mapping      = string
      cache        = optional(string)
      direct_io    = optional(bool)
      expose_acl   = optional(bool)
      expose_xattr = optional(bool)
    })), [])

    # Replication job (proxmox_replication).
    replication = optional(object({
      target   = string
      type     = optional(string, "local")
      schedule = optional(string, "*/15")
      rate     = optional(number)
      comment  = optional(string)
      disable  = optional(bool, false)
    }))

    # SSH key generation. Set to {} to generate a key pair with defaults. Auto-injects public key into initialization.user_account.keys.
    ssh_key = optional(object({
      enabled     = optional(bool, true)
      algorithm   = optional(string, "ED25519")
      rsa_bits    = optional(number, 4096)
      ecdsa_curve = optional(string, "P384")
    }))

    # Cloud-init / Initialization.
    initialization = optional(object({
      datastore_id = optional(string)
      interface    = optional(string)
      file_format  = optional(string)
      upgrade      = optional(bool)

      # Inline DNS configuration.
      dns = optional(object({
        domain  = optional(string)
        servers = optional(list(string))
      }))

      # Inline IP configurations (supports multiple for multi-NIC).
      ip_config = optional(list(object({
        ipv4 = optional(object({
          address = optional(string, "dhcp")
          gateway = optional(string)
        }))
        ipv6 = optional(object({
          address = optional(string)
          gateway = optional(string)
        }))
      })), [])

      # Inline user account.
      user_account = optional(object({
        username = optional(string)
        password = optional(string)
        keys     = optional(list(string), [])
      }))

      # File-based cloud-init: path to local YAML files (read with file()).
      user_data_file    = optional(string)
      network_data_file = optional(string)
      vendor_data_file  = optional(string)
      meta_data_file    = optional(string)

      # Content-based cloud-init: raw string content (use with templatefile()).
      # Takes precedence over the corresponding *_file variable.
      user_data_content    = optional(string)
      network_data_content = optional(string)
      meta_data_content    = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for key, vm in var.vms :
      vm.bios == null ? true : contains(["seabios", "ovmf"], vm.bios)
    ])
    error_message = "bios must be one of: seabios, ovmf."
  }

  validation {
    condition = alltrue([
      for key, vm in var.vms :
      vm.scsi_hardware == null ? true : contains(["virtio-scsi-pci", "virtio-scsi-single", "lsi", "lsi53c810", "megasas", "pvscsi"], vm.scsi_hardware)
    ])
    error_message = "scsi_hardware must be one of: virtio-scsi-pci, virtio-scsi-single, lsi, lsi53c810, megasas, pvscsi."
  }

  validation {
    condition = alltrue([
      for key, vm in var.vms :
      vm.ssh_key == null ? true : contains(["RSA", "ECDSA", "ED25519"], vm.ssh_key.algorithm)
    ])
    error_message = "ssh_key.algorithm must be one of: RSA, ECDSA, ED25519."
  }

  validation {
    condition = alltrue([
      for key, vm in var.vms :
      vm.ssh_key == null ? true : (vm.ssh_key.algorithm != "RSA" || vm.ssh_key.rsa_bits >= 2048)
    ])
    error_message = "ssh_key.rsa_bits must be at least 2048."
  }

  validation {
    condition = alltrue([
      for key, vm in var.vms :
      vm.ssh_key == null ? true : (vm.ssh_key.algorithm != "ECDSA" || contains(["P224", "P256", "P384", "P521"], vm.ssh_key.ecdsa_curve))
    ])
    error_message = "ssh_key.ecdsa_curve must be one of: P224, P256, P384, P521."
  }

  validation {
    condition = alltrue([
      for key, vm in var.vms :
      vm.initialization == null ? true : !(
        vm.initialization.user_account != null &&
        (vm.initialization.user_data_file != null || vm.initialization.user_data_content != null)
      )
    ])
    error_message = "initialization.user_account conflicts with initialization.user_data_file and initialization.user_data_content."
  }

  validation {
    condition = alltrue([
      for key, vm in var.vms :
      vm.initialization == null ? true : !(
        length(vm.initialization.ip_config) > 0 &&
        (vm.initialization.network_data_file != null || vm.initialization.network_data_content != null)
      )
    ])
    error_message = "initialization.network_data_file/network_data_content conflicts with initialization.ip_config."
  }

  validation {
    condition = alltrue([
      for key, vm in var.vms :
      vm.initialization == null ? true : (
        vm.initialization.file_format == null ? true :
        contains(["qcow2", "raw", "vmdk"], vm.initialization.file_format)
      )
    ])
    error_message = "initialization.file_format must be one of: qcow2, raw, vmdk."
  }
}

variable "save_ssh_keys_locally" {
  description = "Whether to save generated SSH private keys to local files."
  type        = bool
  default     = true
}

variable "local_key_directory" {
  description = "Directory where to save SSH key files. Files will be named {vm_name}.key and {vm_name}.pub."
  type        = string
  default     = "."
}

variable "common_node_name" {
  description = "Default Proxmox node name applied to all VMs."
  type        = string
  default     = "pve"
}

variable "common_tags" {
  description = "Tags applied to all VMs in addition to per-VM tags."
  type        = list(string)
  default     = ["terraform"]
}

variable "common_datastore_id" {
  description = "Default datastore ID for VM disks and cloud-init."
  type        = string
  default     = "local-zfs"
}

variable "common_snippet_datastore_id" {
  description = "Default datastore ID for cloud-init snippet files (must support snippets content type)."
  type        = string
  default     = "local"
}

variable "common_snippet_upload_mode" {
  description = "SSH upload mode for cloud-init snippet files. `stream` pipes through an SSH shell session (uses sudo where needed), `sftp` uploads via the SFTP subsystem (requires direct write permission on the target directory)."
  type        = string
  default     = "stream"

  validation {
    condition     = contains(["stream", "sftp"], var.common_snippet_upload_mode)
    error_message = "common_snippet_upload_mode must be one of: stream, sftp."
  }
}

variable "common_dns" {
  description = "Default DNS configuration applied to all VMs using inline initialization."
  type = object({
    domain  = optional(string)
    servers = optional(list(string))
  })
  default = null
}

variable "common_bios" {
  description = "Default BIOS type applied when a VM does not define bios."
  type        = string
  default     = null

  validation {
    condition     = var.common_bios == null ? true : contains(["seabios", "ovmf"], var.common_bios)
    error_message = "common_bios must be one of: seabios, ovmf."
  }
}

variable "common_efi_disk" {
  description = "Default EFI disk settings applied when a VM does not define efi_disk. Useful with common_bios = ovmf."
  type = object({
    datastore_id      = optional(string)
    file_format       = optional(string, "raw")
    type              = optional(string, "4m")
    pre_enrolled_keys = optional(bool, false)
  })
  default = null
}

variable "common_disk_interface" {
  description = "Default disk interface used when a disk item does not define interface."
  type        = string
  default     = null
}

variable "common_agent" {
  description = "Default QEMU agent settings applied when a VM does not define agent."
  type = object({
    enabled = optional(bool)
    trim    = optional(bool)
    type    = optional(string)
    timeout = optional(string)
    wait_for_ip = optional(object({
      ipv4 = optional(bool, false)
      ipv6 = optional(bool, false)
    }))
  })
  default = null
}

variable "common_rng" {
  description = "Default RNG device settings applied when a VM does not define rng."
  type = object({
    source    = string
    max_bytes = optional(number, 1024)
    period    = optional(number, 1000)
  })
  default = null
}

variable "common_network_device" {
  description = "Default network device settings merged into each VM network_devices item (unless inherit_common is false). If a VM has no network_devices, this becomes the single NIC."
  type = object({
    bridge       = optional(string)
    model        = optional(string)
    vlan_id      = optional(number)
    mac_address  = optional(string)
    firewall     = optional(bool)
    disconnected = optional(bool)
    mtu          = optional(number)
    queues       = optional(number)
    rate_limit   = optional(number)
    trunks       = optional(string)
  })
  default = null
}
