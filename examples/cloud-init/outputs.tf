output "vm_ids" {
  description = "Map of VM names to Proxmox VM IDs."
  value       = module.vm.vm_ids
}

output "vm_ipv4" {
  description = "Map of VM names to IPv4 addresses reported by the QEMU guest agent."
  value       = module.vm.vm_ipv4_addresses
}

output "ssh_key_files" {
  description = "Map of VM names to local file paths of generated SSH private keys."
  value       = module.vm.ssh_private_key_file_paths
}

output "ssh_connection" {
  description = "SSH connection commands per VM."
  value = {
    for name, path in module.vm.ssh_private_key_file_paths :
    name => "ssh -i ${path} admin@10.20.0.20"
  }
}
