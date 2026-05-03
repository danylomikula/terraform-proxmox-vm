# Complete Example

## Purpose
This is the end-to-end example showing full module composition:
- Download image with `download-file`.
- Create multiple VMs with different settings through the VM module.
- Use rich outputs for operational workflows.

## What It Creates
- One downloaded cloud image:
  - `ubuntu-24.04-cloudimg-amd64.qcow2`
- Two VMs:
  - `k8s-master`
  - `k8s-worker-01`

### k8s-master
- BIOS `ovmf` + `efi_disk`
- CPU `4` cores
- Memory `8192 MB`
- Two disks (`scsi0`, `scsi1`)
- Two NICs (second NIC VLAN `100`)
- Two inline `ip_config` blocks
- Inline `user_account`
- QEMU agent enabled
- Generated SSH key

### k8s-worker-01
- CPU `2` cores
- Memory `4096 MB`
- One imported disk
- Inherits common NIC defaults
- Inline static IP + user
- QEMU agent enabled
- Generated SSH key

## Prerequisites
- Proxmox VE API access.
- Datastore `local` for image downloads.
- Datastore `local-lvm` for VM disks.

## Usage
```bash
cd examples/complete

terraform init
terraform plan \
  -var="proxmox_endpoint=https://pve:8006" \
  -var="proxmox_api_token=root@pam!token=secret"

terraform apply \
  -var="proxmox_endpoint=https://pve:8006" \
  -var="proxmox_api_token=root@pam!token=secret"
```

## Cleanup
```bash
terraform destroy \
  -var="proxmox_endpoint=https://pve:8006" \
  -var="proxmox_api_token=root@pam!token=secret"
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.105.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_images"></a> [images](#module\_images) | danylomikula/download-file/proxmox | 1.0.0 |
| <a name="module_vms"></a> [vms](#module\_vms) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_proxmox_api_token"></a> [proxmox\_api\_token](#input\_proxmox\_api\_token) | Proxmox API token. | `string` | n/a | yes |
| <a name="input_proxmox_endpoint"></a> [proxmox\_endpoint](#input\_proxmox\_endpoint) | Proxmox API endpoint URL. | `string` | n/a | yes |
| <a name="input_proxmox_insecure"></a> [proxmox\_insecure](#input\_proxmox\_insecure) | Skip TLS verification. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_downloaded_images"></a> [downloaded\_images](#output\_downloaded\_images) | Map of downloaded image keys to Proxmox file IDs. |
| <a name="output_ssh_connection_commands"></a> [ssh\_connection\_commands](#output\_ssh\_connection\_commands) | SSH connection commands for each VM. |
| <a name="output_ssh_key_files"></a> [ssh\_key\_files](#output\_ssh\_key\_files) | Map of VM names to local file paths of generated SSH private keys. |
| <a name="output_vm_ids"></a> [vm\_ids](#output\_vm\_ids) | Map of VM names to Proxmox VM IDs. |
| <a name="output_vm_ipv4"></a> [vm\_ipv4](#output\_vm\_ipv4) | Map of VM names to IPv4 addresses reported by the QEMU guest agent. |
| <a name="output_vms_by_node"></a> [vms\_by\_node](#output\_vms\_by\_node) | VMs grouped by Proxmox node. |
| <a name="output_vms_by_tag"></a> [vms\_by\_tag](#output\_vms\_by\_tag) | VMs grouped by tag. |
<!-- END_TF_DOCS -->
