output "vm_ids" {
  description = "Map of VM names to Proxmox VM IDs."
  value       = module.vm.vm_ids
}

output "vm_ipv4" {
  description = "Map of VM names to IPv4 addresses reported by the QEMU guest agent."
  value       = module.vm.vm_ipv4_addresses
}
