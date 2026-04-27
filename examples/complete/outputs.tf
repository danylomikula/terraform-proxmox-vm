output "vm_ids" {
  description = "Map of VM names to Proxmox VM IDs."
  value       = module.vms.vm_ids
}

output "vm_ipv4" {
  description = "Map of VM names to IPv4 addresses reported by the QEMU guest agent."
  value       = module.vms.vm_ipv4_addresses
}

output "vms_by_node" {
  description = "VMs grouped by Proxmox node."
  value       = module.vms.vms_by_node
}

output "vms_by_tag" {
  description = "VMs grouped by tag."
  value       = module.vms.vms_by_tag
}

output "ssh_key_files" {
  description = "Map of VM names to local file paths of generated SSH private keys."
  value       = module.vms.ssh_private_key_file_paths
}

output "ssh_connection_commands" {
  description = "SSH connection commands for each VM."
  value = {
    for name, path in module.vms.ssh_private_key_file_paths :
    name => "ssh -i ${path} admin@<ip>"
  }
}

output "downloaded_images" {
  description = "Map of downloaded image keys to Proxmox file IDs."
  value       = module.images.file_ids
}
