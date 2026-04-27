variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL."
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token."
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification."
  type        = bool
  default     = false
}

variable "template_vm_id" {
  description = "VM ID of the template to clone from."
  type        = number
}
