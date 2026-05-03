locals {
  # VMs that need SSH key generation.
  vms_with_ssh_key = {
    for key, vm in var.vms : key => vm.ssh_key
    if vm.ssh_key != null && vm.ssh_key.enabled
  }

  # VMs that should save keys locally.
  keys_to_save = var.save_ssh_keys_locally ? local.vms_with_ssh_key : {}

  # Defaults applied to all network devices unless overridden.
  network_device_defaults = {
    model        = "virtio"
    firewall     = false
    disconnected = false
  }

  # Optional shared network device settings merged into per-VM NICs.
  common_network_device = var.common_network_device != null ? {
    bridge       = var.common_network_device.bridge
    model        = var.common_network_device.model
    vlan_id      = var.common_network_device.vlan_id
    mac_address  = var.common_network_device.mac_address
    firewall     = var.common_network_device.firewall
    disconnected = var.common_network_device.disconnected
    mtu          = var.common_network_device.mtu
    queues       = var.common_network_device.queues
    rate_limit   = var.common_network_device.rate_limit
    trunks       = var.common_network_device.trunks
  } : null

  vms_config = {
    for key, vm in var.vms : key => {
      # Core.
      vm_id               = vm.vm_id
      node_name           = coalesce(vm.node_name, var.common_node_name)
      description         = vm.description
      tags                = distinct(concat(var.common_tags, vm.tags))
      on_boot             = vm.on_boot
      started             = vm.started
      reboot              = vm.reboot
      pool_id             = vm.pool_id
      scsi_hardware       = vm.scsi_hardware
      machine             = vm.machine
      bios                = coalesce(vm.bios, var.common_bios, "seabios")
      tablet_device       = vm.tablet_device
      template            = vm.template
      protection          = vm.protection
      acpi                = vm.acpi
      keyboard_layout     = vm.keyboard_layout
      kvm_arguments       = vm.kvm_arguments
      migrate             = vm.migrate
      reboot_after_update = vm.reboot_after_update
      boot_order          = vm.boot_order
      hotplug             = vm.hotplug
      hook_script_file_id = vm.hook_script_file_id

      # Destroy behavior.
      stop_on_destroy                      = vm.stop_on_destroy
      purge_on_destroy                     = vm.purge_on_destroy
      delete_unreferenced_disks_on_destroy = vm.delete_unreferenced_disks_on_destroy

      # Timeouts.
      timeout_clone       = vm.timeout_clone
      timeout_create      = vm.timeout_create
      timeout_reboot      = vm.timeout_reboot
      timeout_shutdown_vm = vm.timeout_shutdown_vm
      timeout_start_vm    = vm.timeout_start_vm
      timeout_stop_vm     = vm.timeout_stop_vm
      timeout_migrate     = vm.timeout_migrate

      # Agent (VM value overrides global default).
      agent = vm.agent != null ? vm.agent : var.common_agent

      # CPU with defaults.
      cpu = vm.cpu != null ? vm.cpu : {
        cores        = 2
        sockets      = 1
        hotplugged   = 0
        type         = "x86-64-v3"
        architecture = "x86_64"
        flags        = null
        units        = null
        numa         = false
        limit        = null
        affinity     = null
      }

      # Memory with defaults.
      memory = vm.memory != null ? vm.memory : {
        dedicated      = 4096
        floating       = 0
        shared         = 0
        hugepages      = null
        keep_hugepages = null
      }

      # Disks with common_datastore_id fallback.
      disks = [
        for disk in vm.disks : merge(disk, {
          datastore_id = coalesce(disk.datastore_id, var.common_datastore_id)
          interface    = coalesce(disk.interface, var.common_disk_interface, "scsi0")
        })
      ]

      # EFI disk (VM value overrides global default).
      efi_disk = vm.efi_disk != null ? merge(vm.efi_disk, {
        datastore_id = coalesce(vm.efi_disk.datastore_id, var.common_datastore_id)
        }) : (
        var.common_efi_disk != null ? merge(var.common_efi_disk, {
          datastore_id = coalesce(var.common_efi_disk.datastore_id, var.common_datastore_id)
        }) : null
      )

      # TPM state.
      tpm_state = vm.tpm_state != null ? merge(vm.tpm_state, {
        datastore_id = coalesce(vm.tpm_state.datastore_id, var.common_datastore_id)
      }) : null

      # CDROM.
      cdrom = vm.cdrom

      # Network devices: merge per-NIC overrides with optional common defaults.
      network_devices = length(vm.network_devices) > 0 ? [
        for nic in vm.network_devices : {
          bridge       = nic.bridge != null ? nic.bridge : (nic.inherit_common && local.common_network_device != null ? local.common_network_device.bridge : null)
          model        = coalesce(nic.model, nic.inherit_common && local.common_network_device != null ? local.common_network_device.model : null, local.network_device_defaults.model)
          vlan_id      = nic.vlan_id != null ? nic.vlan_id : (nic.inherit_common && local.common_network_device != null ? local.common_network_device.vlan_id : null)
          mac_address  = nic.mac_address != null ? nic.mac_address : (nic.inherit_common && local.common_network_device != null ? local.common_network_device.mac_address : null)
          firewall     = coalesce(nic.firewall, nic.inherit_common && local.common_network_device != null ? local.common_network_device.firewall : null, local.network_device_defaults.firewall)
          disconnected = coalesce(nic.disconnected, nic.inherit_common && local.common_network_device != null ? local.common_network_device.disconnected : null, local.network_device_defaults.disconnected)
          mtu          = nic.mtu != null ? nic.mtu : (nic.inherit_common && local.common_network_device != null ? local.common_network_device.mtu : null)
          queues       = nic.queues != null ? nic.queues : (nic.inherit_common && local.common_network_device != null ? local.common_network_device.queues : null)
          rate_limit   = nic.rate_limit != null ? nic.rate_limit : (nic.inherit_common && local.common_network_device != null ? local.common_network_device.rate_limit : null)
          trunks       = nic.trunks != null ? nic.trunks : (nic.inherit_common && local.common_network_device != null ? local.common_network_device.trunks : null)
        }
        ] : (
        local.common_network_device != null ? [{
          bridge       = local.common_network_device.bridge
          model        = coalesce(local.common_network_device.model, local.network_device_defaults.model)
          vlan_id      = local.common_network_device.vlan_id
          mac_address  = local.common_network_device.mac_address
          firewall     = coalesce(local.common_network_device.firewall, local.network_device_defaults.firewall)
          disconnected = coalesce(local.common_network_device.disconnected, local.network_device_defaults.disconnected)
          mtu          = local.common_network_device.mtu
          queues       = local.common_network_device.queues
          rate_limit   = local.common_network_device.rate_limit
          trunks       = local.common_network_device.trunks
        }] : []
      )

      # Host PCI.
      hostpci = vm.hostpci

      # USB.
      usb = vm.usb

      # Operating system (always set, defaults to l26).
      operating_system = vm.operating_system != null ? vm.operating_system : { type = "l26" }

      # VGA.
      vga = vm.vga

      # Startup.
      startup = vm.startup

      # Serial device.
      serial_device = vm.serial_device

      # Clone.
      clone = vm.clone

      # Audio device.
      audio_device = vm.audio_device

      # AMD SEV.
      amd_sev = vm.amd_sev

      # NUMA.
      numa = vm.numa

      # SMBIOS.
      smbios = vm.smbios

      # RNG (VM value overrides global default).
      rng = vm.rng != null ? vm.rng : var.common_rng

      # Watchdog.
      watchdog = vm.watchdog

      # VirtioFS.
      virtiofs = vm.virtiofs

      # Replication.
      replication = vm.replication

      # SSH key.
      ssh_key = vm.ssh_key

      # Initialization with merged common_dns and auto-injected SSH key.
      initialization = vm.initialization != null ? {
        datastore_id = coalesce(vm.initialization.datastore_id, var.common_datastore_id)
        interface    = vm.initialization.interface
        file_format  = vm.initialization.file_format
        upgrade      = vm.initialization.upgrade
        dns          = vm.initialization.dns != null ? vm.initialization.dns : var.common_dns
        ip_config    = vm.initialization.ip_config
        user_account = vm.initialization.user_account != null ? {
          username = vm.initialization.user_account.username
          password = vm.initialization.user_account.password
          keys     = vm.initialization.user_account.keys
        } : null
        user_data_file       = vm.initialization.user_data_file
        user_data_content    = vm.initialization.user_data_content
        network_data_file    = vm.initialization.network_data_file
        network_data_content = vm.initialization.network_data_content
        vendor_data_file     = vm.initialization.vendor_data_file
        meta_data_file       = vm.initialization.meta_data_file
        meta_data_content    = vm.initialization.meta_data_content
      } : null
    }
  }

  # Cloud-init snippet file uploads.
  #
  # Users may pass sensitive values via `*_content` fields (e.g. rendered
  # templates containing passwords). Terraform propagates the sensitive mark
  # through both the content itself AND through any boolean derived from it
  # (like `content != null`), which would contaminate the filter predicate
  # and the whole resulting map — making it unusable with `for_each`.
  #
  # Pattern:
  #   1. Build the iteration map with ONLY non-sensitive metadata (VM key,
  #      node_name) — no sensitive content is placed inside the map.
  #   2. Wrap with `nonsensitive()` to strip the sensitive mark that leaked
  #      via the filter predicate. VM keys and node names are explicitly
  #      non-secret (they're already visible in plan output and state).
  #   3. Look up the actual content (possibly sensitive) inside the resource
  #      body via `local.vms_config[each.key]`, where sensitive values are
  #      permitted.
  user_data_snippets = nonsensitive({
    for key, vm in local.vms_config : key => {
      node_name = vm.node_name
    }
    if vm.initialization != null && (vm.initialization.user_data_file != null || vm.initialization.user_data_content != null)
  })

  network_data_snippets = nonsensitive({
    for key, vm in local.vms_config : key => {
      node_name = vm.node_name
    }
    if vm.initialization != null && (vm.initialization.network_data_file != null || vm.initialization.network_data_content != null)
  })

  vendor_data_snippets = nonsensitive({
    for key, vm in local.vms_config : key => {
      node_name = vm.node_name
    }
    if vm.initialization != null && vm.initialization.vendor_data_file != null
  })

  meta_data_snippets = nonsensitive({
    for key, vm in local.vms_config : key => {
      node_name = vm.node_name
    }
    if vm.initialization != null && (vm.initialization.meta_data_file != null || vm.initialization.meta_data_content != null)
  })
}

# SSH key generation.
resource "tls_private_key" "this" {
  for_each = local.vms_with_ssh_key

  algorithm   = each.value.algorithm
  rsa_bits    = each.value.algorithm == "RSA" ? each.value.rsa_bits : null
  ecdsa_curve = each.value.algorithm == "ECDSA" ? each.value.ecdsa_curve : null
}

resource "local_sensitive_file" "private_key" {
  for_each = local.keys_to_save

  content         = tls_private_key.this[each.key].private_key_openssh
  filename        = "${var.local_key_directory}/${each.key}.key"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  for_each = local.keys_to_save

  content         = tls_private_key.this[each.key].public_key_openssh
  filename        = "${var.local_key_directory}/${each.key}.pub"
  file_permission = "0644"
}

# Cloud-init snippet file resources.
resource "proxmox_virtual_environment_file" "user_data" {
  for_each = local.user_data_snippets

  node_name    = each.value.node_name
  datastore_id = var.common_snippet_datastore_id
  content_type = "snippets"
  upload_mode  = var.common_snippet_upload_mode

  source_raw {
    # Content is resolved here (not in locals) so that sensitive values
    # passed through `user_data_content` don't propagate into `for_each`.
    # Replace {{ssh_public_key}} placeholder with the generated SSH public key (if any).
    data = replace(
      local.vms_config[each.key].initialization.user_data_content != null ? local.vms_config[each.key].initialization.user_data_content : file(local.vms_config[each.key].initialization.user_data_file),
      "{{ssh_public_key}}",
      contains(keys(tls_private_key.this), each.key) ? trimspace(tls_private_key.this[each.key].public_key_openssh) : ""
    )
    file_name = "${each.key}-user-data.yml"
  }
}

resource "proxmox_virtual_environment_file" "network_data" {
  for_each = local.network_data_snippets

  node_name    = each.value.node_name
  datastore_id = var.common_snippet_datastore_id
  content_type = "snippets"
  upload_mode  = var.common_snippet_upload_mode

  source_raw {
    data = (
      local.vms_config[each.key].initialization.network_data_content != null
      ? local.vms_config[each.key].initialization.network_data_content
      : file(local.vms_config[each.key].initialization.network_data_file)
    )
    file_name = "${each.key}-network-data.yml"
  }
}

resource "proxmox_virtual_environment_file" "vendor_data" {
  for_each = local.vendor_data_snippets

  node_name    = each.value.node_name
  datastore_id = var.common_snippet_datastore_id
  content_type = "snippets"
  upload_mode  = var.common_snippet_upload_mode

  source_raw {
    data      = file(local.vms_config[each.key].initialization.vendor_data_file)
    file_name = "${each.key}-vendor-data.yml"
  }
}

resource "proxmox_virtual_environment_file" "meta_data" {
  for_each = local.meta_data_snippets

  node_name    = each.value.node_name
  datastore_id = var.common_snippet_datastore_id
  content_type = "snippets"
  upload_mode  = var.common_snippet_upload_mode

  source_raw {
    data = (
      local.vms_config[each.key].initialization.meta_data_content != null
      ? local.vms_config[each.key].initialization.meta_data_content
      : file(local.vms_config[each.key].initialization.meta_data_file)
    )
    file_name = "${each.key}-meta-data.yml"
  }
}

locals {
  vms_with_replication = {
    for key, vm in local.vms_config : key => vm.replication
    if vm.replication != null
  }
}

# Replication jobs (one per VM that has replication configured).
resource "proxmox_replication" "this" {
  for_each = local.vms_with_replication

  id       = "${proxmox_virtual_environment_vm.this[each.key].vm_id}-0"
  target   = each.value.target
  type     = each.value.type
  schedule = each.value.schedule
  rate     = each.value.rate
  comment  = each.value.comment
  disable  = each.value.disable
}

resource "proxmox_virtual_environment_vm" "this" {
  for_each = local.vms_config

  name                = each.key
  vm_id               = each.value.vm_id
  description         = each.value.description
  tags                = sort(each.value.tags)
  on_boot             = each.value.on_boot
  started             = each.value.started
  reboot              = each.value.reboot
  node_name           = each.value.node_name
  pool_id             = each.value.pool_id
  scsi_hardware       = each.value.scsi_hardware
  machine             = each.value.machine
  bios                = each.value.bios
  tablet_device       = each.value.tablet_device
  template            = each.value.template
  protection          = each.value.protection
  acpi                = each.value.acpi
  keyboard_layout     = each.value.keyboard_layout
  kvm_arguments       = each.value.kvm_arguments
  migrate             = each.value.migrate
  reboot_after_update = each.value.reboot_after_update
  boot_order          = each.value.boot_order
  hotplug             = each.value.hotplug
  hook_script_file_id = each.value.hook_script_file_id

  stop_on_destroy                      = each.value.stop_on_destroy
  purge_on_destroy                     = each.value.purge_on_destroy
  delete_unreferenced_disks_on_destroy = each.value.delete_unreferenced_disks_on_destroy

  timeout_clone       = each.value.timeout_clone
  timeout_create      = each.value.timeout_create
  timeout_reboot      = each.value.timeout_reboot
  timeout_shutdown_vm = each.value.timeout_shutdown_vm
  timeout_start_vm    = each.value.timeout_start_vm
  timeout_stop_vm     = each.value.timeout_stop_vm
  timeout_migrate     = each.value.timeout_migrate

  # Agent block.
  dynamic "agent" {
    for_each = each.value.agent != null ? [each.value.agent] : []
    content {
      enabled = agent.value.enabled
      trim    = agent.value.trim
      type    = agent.value.type
      timeout = agent.value.timeout

      dynamic "wait_for_ip" {
        for_each = agent.value.wait_for_ip != null ? [agent.value.wait_for_ip] : []
        content {
          ipv4 = wait_for_ip.value.ipv4
          ipv6 = wait_for_ip.value.ipv6
        }
      }
    }
  }

  # CPU block.
  cpu {
    cores        = each.value.cpu.cores
    sockets      = each.value.cpu.sockets
    hotplugged   = each.value.cpu.hotplugged
    type         = each.value.cpu.type
    architecture = each.value.cpu.architecture
    flags        = each.value.cpu.flags
    units        = each.value.cpu.units
    numa         = each.value.cpu.numa
    limit        = each.value.cpu.limit
    affinity     = each.value.cpu.affinity
  }

  # Memory block.
  memory {
    dedicated      = each.value.memory.dedicated
    floating       = each.value.memory.floating
    shared         = each.value.memory.shared
    hugepages      = each.value.memory.hugepages
    keep_hugepages = each.value.memory.keep_hugepages
  }

  # Disk blocks (multiple).
  dynamic "disk" {
    for_each = each.value.disks
    content {
      datastore_id      = disk.value.datastore_id
      file_id           = disk.value.file_id
      import_from       = disk.value.import_from
      interface         = disk.value.interface
      size              = disk.value.size
      iothread          = disk.value.iothread
      discard           = disk.value.discard
      backup            = disk.value.backup
      cache             = disk.value.cache
      ssd               = disk.value.ssd
      file_format       = disk.value.file_format
      aio               = disk.value.aio
      replicate         = disk.value.replicate
      serial            = disk.value.serial
      path_in_datastore = disk.value.path_in_datastore

      dynamic "speed" {
        for_each = disk.value.speed != null ? [disk.value.speed] : []
        content {
          iops_read            = speed.value.iops_read
          iops_read_burstable  = speed.value.iops_read_burstable
          iops_write           = speed.value.iops_write
          iops_write_burstable = speed.value.iops_write_burstable
          read                 = speed.value.read
          read_burstable       = speed.value.read_burstable
          write                = speed.value.write
          write_burstable      = speed.value.write_burstable
        }
      }
    }
  }

  # EFI disk.
  dynamic "efi_disk" {
    for_each = each.value.efi_disk != null ? [each.value.efi_disk] : []
    content {
      datastore_id      = efi_disk.value.datastore_id
      file_format       = efi_disk.value.file_format
      type              = efi_disk.value.type
      pre_enrolled_keys = efi_disk.value.pre_enrolled_keys
    }
  }

  # TPM state.
  dynamic "tpm_state" {
    for_each = each.value.tpm_state != null ? [each.value.tpm_state] : []
    content {
      datastore_id = tpm_state.value.datastore_id
      version      = tpm_state.value.version
    }
  }

  # CDROM.
  dynamic "cdrom" {
    for_each = each.value.cdrom != null ? [each.value.cdrom] : []
    content {
      file_id   = cdrom.value.file_id
      interface = cdrom.value.interface
    }
  }

  # Network devices (multiple).
  dynamic "network_device" {
    for_each = each.value.network_devices
    content {
      bridge       = network_device.value.bridge
      model        = network_device.value.model
      vlan_id      = network_device.value.vlan_id
      mac_address  = network_device.value.mac_address
      firewall     = network_device.value.firewall
      disconnected = network_device.value.disconnected
      mtu          = network_device.value.mtu
      queues       = network_device.value.queues
      rate_limit   = network_device.value.rate_limit
      trunks       = network_device.value.trunks
    }
  }

  # Host PCI passthrough (multiple).
  dynamic "hostpci" {
    for_each = each.value.hostpci
    content {
      device   = hostpci.value.device
      mapping  = hostpci.value.mapping
      id       = hostpci.value.id
      mdev     = hostpci.value.mdev
      rombar   = hostpci.value.rombar
      pcie     = hostpci.value.pcie
      xvga     = hostpci.value.xvga
      rom_file = hostpci.value.rom_file
    }
  }

  # USB passthrough (multiple).
  dynamic "usb" {
    for_each = each.value.usb
    content {
      host    = usb.value.host
      mapping = usb.value.mapping
      usb3    = usb.value.usb3
    }
  }

  # Operating system.
  operating_system {
    type = each.value.operating_system.type
  }

  # VGA.
  dynamic "vga" {
    for_each = each.value.vga != null ? [each.value.vga] : []
    content {
      type      = vga.value.type
      memory    = vga.value.memory
      clipboard = vga.value.clipboard
    }
  }

  # Startup.
  dynamic "startup" {
    for_each = each.value.startup != null ? [each.value.startup] : []
    content {
      order      = startup.value.order
      up_delay   = startup.value.up_delay
      down_delay = startup.value.down_delay
    }
  }

  # Serial device.
  dynamic "serial_device" {
    for_each = each.value.serial_device != null ? [each.value.serial_device] : []
    content {
      device = serial_device.value.device
    }
  }

  # Clone.
  dynamic "clone" {
    for_each = each.value.clone != null ? [each.value.clone] : []
    content {
      vm_id        = clone.value.vm_id
      datastore_id = clone.value.datastore_id
      node_name    = clone.value.node_name
      retries      = clone.value.retries
      full         = clone.value.full
    }
  }

  # Audio device.
  dynamic "audio_device" {
    for_each = each.value.audio_device != null ? [each.value.audio_device] : []
    content {
      device  = audio_device.value.device
      driver  = audio_device.value.driver
      enabled = audio_device.value.enabled
    }
  }

  # AMD SEV (Secure Encrypted Virtualization).
  dynamic "amd_sev" {
    for_each = each.value.amd_sev != null ? [each.value.amd_sev] : []
    content {
      type           = amd_sev.value.type
      allow_smt      = amd_sev.value.allow_smt
      kernel_hashes  = amd_sev.value.kernel_hashes
      no_debug       = amd_sev.value.no_debug
      no_key_sharing = amd_sev.value.no_key_sharing
    }
  }

  # NUMA topology (multiple nodes).
  dynamic "numa" {
    for_each = each.value.numa
    content {
      device    = numa.value.device
      cpus      = numa.value.cpus
      memory    = numa.value.memory
      hostnodes = numa.value.hostnodes
      policy    = numa.value.policy
    }
  }

  # SMBIOS.
  dynamic "smbios" {
    for_each = each.value.smbios != null ? [each.value.smbios] : []
    content {
      family       = smbios.value.family
      manufacturer = smbios.value.manufacturer
      product      = smbios.value.product
      serial       = smbios.value.serial
      sku          = smbios.value.sku
      uuid         = smbios.value.uuid
      version      = smbios.value.version
    }
  }

  # Random number generator.
  dynamic "rng" {
    for_each = each.value.rng != null ? [each.value.rng] : []
    content {
      source    = rng.value.source
      max_bytes = rng.value.max_bytes
      period    = rng.value.period
    }
  }

  # Watchdog device.
  dynamic "watchdog" {
    for_each = each.value.watchdog != null ? [each.value.watchdog] : []
    content {
      enabled = watchdog.value.enabled
      model   = watchdog.value.model
      action  = watchdog.value.action
    }
  }

  # VirtioFS shared directories (multiple mounts).
  dynamic "virtiofs" {
    for_each = each.value.virtiofs
    content {
      mapping      = virtiofs.value.mapping
      cache        = virtiofs.value.cache
      direct_io    = virtiofs.value.direct_io
      expose_acl   = virtiofs.value.expose_acl
      expose_xattr = virtiofs.value.expose_xattr
    }
  }

  # Cloud-init / Initialization.
  dynamic "initialization" {
    for_each = each.value.initialization != null ? [each.value.initialization] : []
    content {
      datastore_id = initialization.value.datastore_id
      interface    = initialization.value.interface
      file_format  = initialization.value.file_format
      upgrade      = initialization.value.upgrade

      # File-based cloud-init (auto-uploaded from local YAML files).
      user_data_file_id    = contains(keys(proxmox_virtual_environment_file.user_data), each.key) ? proxmox_virtual_environment_file.user_data[each.key].id : null
      network_data_file_id = contains(keys(proxmox_virtual_environment_file.network_data), each.key) ? proxmox_virtual_environment_file.network_data[each.key].id : null
      vendor_data_file_id  = contains(keys(proxmox_virtual_environment_file.vendor_data), each.key) ? proxmox_virtual_environment_file.vendor_data[each.key].id : null
      meta_data_file_id    = contains(keys(proxmox_virtual_environment_file.meta_data), each.key) ? proxmox_virtual_environment_file.meta_data[each.key].id : null

      # Inline DNS.
      dynamic "dns" {
        for_each = initialization.value.dns != null ? [initialization.value.dns] : []
        content {
          domain  = dns.value.domain
          servers = dns.value.servers
        }
      }

      # Inline IP configs (supports multiple for multi-NIC).
      dynamic "ip_config" {
        for_each = initialization.value.ip_config
        content {
          dynamic "ipv4" {
            for_each = ip_config.value.ipv4 != null ? [ip_config.value.ipv4] : []
            content {
              address = ipv4.value.address
              gateway = ipv4.value.gateway
            }
          }
          dynamic "ipv6" {
            for_each = ip_config.value.ipv6 != null ? [ip_config.value.ipv6] : []
            content {
              address = ipv6.value.address
              gateway = ipv6.value.gateway
            }
          }
        }
      }

      # Inline user account with auto-injected SSH key.
      dynamic "user_account" {
        for_each = initialization.value.user_account != null ? [initialization.value.user_account] : []
        content {
          username = user_account.value.username
          password = user_account.value.password
          keys = distinct(concat(
            user_account.value.keys,
            contains(keys(tls_private_key.this), each.key) ? [trimspace(tls_private_key.this[each.key].public_key_openssh)] : []
          ))
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      initialization,
    ]

    precondition {
      condition     = each.value.bios != "ovmf" || each.value.efi_disk != null
      error_message = "EFI disk is required when BIOS is ovmf. Set vms[\"<name>\"].efi_disk or common_efi_disk."
    }
  }
}
