output "vms" {
  description = "Map of VM resources with selected attributes (id, vm_id, name, node_name, tags, IPs, MACs)."
  value = {
    for key, vm in proxmox_virtual_environment_vm.this : key => {
      id             = vm.id
      vm_id          = vm.vm_id
      name           = vm.name
      node_name      = vm.node_name
      description    = vm.description
      tags           = vm.tags
      ipv4_addresses = vm.ipv4_addresses
      ipv6_addresses = vm.ipv6_addresses
      mac_addresses  = vm.mac_addresses
    }
  }
}

output "vm_ids" {
  description = "Map of VM names to their Proxmox VM IDs."
  value = {
    for key, vm in proxmox_virtual_environment_vm.this : key => vm.vm_id
  }
}

output "vm_ipv4_addresses" {
  description = "Map of VM names to their IPv4 addresses (list of lists, per interface)."
  value = {
    for key, vm in proxmox_virtual_environment_vm.this : key => vm.ipv4_addresses
  }
}

output "vm_ipv6_addresses" {
  description = "Map of VM names to their IPv6 addresses (list of lists, per interface)."
  value = {
    for key, vm in proxmox_virtual_environment_vm.this : key => vm.ipv6_addresses
  }
}

output "vm_mac_addresses" {
  description = "Map of VM names to their MAC addresses."
  value = {
    for key, vm in proxmox_virtual_environment_vm.this : key => vm.mac_addresses
  }
}

output "vms_by_node" {
  description = "Map of node names to lists of VM IDs on that node."
  value = {
    for node in distinct([for vm in values(proxmox_virtual_environment_vm.this) : vm.node_name]) :
    node => [
      for vm in values(proxmox_virtual_environment_vm.this) : vm.vm_id
      if vm.node_name == node
    ]
  }
}

output "ssh_public_keys" {
  description = "Map of VM names to their generated SSH public keys in OpenSSH format."
  value = {
    for key, tls_key in tls_private_key.this : key => trimspace(tls_key.public_key_openssh)
  }
  sensitive = true
}

output "ssh_private_keys" {
  description = "Map of VM names to their generated SSH private keys in PEM format."
  value = {
    for key, tls_key in tls_private_key.this : key => tls_key.private_key_pem
  }
  sensitive = true
}

output "ssh_private_key_file_paths" {
  description = "Map of VM names to their saved private key file paths."
  value = {
    for key, file in local_sensitive_file.private_key : key => file.filename
  }
}

output "vms_by_tag" {
  description = "Map of tags to lists of VM IDs with that tag."
  value = {
    for tag in distinct(flatten([for vm in values(proxmox_virtual_environment_vm.this) : vm.tags])) :
    tag => [
      for vm in values(proxmox_virtual_environment_vm.this) : vm.vm_id
      if contains(vm.tags, tag)
    ]
  }
}
