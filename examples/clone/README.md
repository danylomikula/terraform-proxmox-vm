# Clone Example

## Purpose
This example creates a VM by cloning an existing template VM.

## What It Creates
- One cloned VM: `app-01`
- Clone source: `template_vm_id` (input variable)
- Clone mode: full clone (`full = true`)
- CPU: `2` cores
- Memory: `4096 MB`
- One NIC on `vmbr0`
- Inline cloud-init:
  - IPv4: `10.0.0.10/24`
  - Gateway: `10.0.0.1`
  - Username: `admin`

## Prerequisites
- Proxmox VE API access.
- A source template VM already exists in Proxmox.
- `template_vm_id` points to that template.

## Usage
```bash
cd examples/clone

terraform init
terraform plan \
  -var="proxmox_endpoint=https://pve:8006" \
  -var="proxmox_api_token=root@pam!token=secret" \
  -var="template_vm_id=9000"

terraform apply \
  -var="proxmox_endpoint=https://pve:8006" \
  -var="proxmox_api_token=root@pam!token=secret" \
  -var="template_vm_id=9000"
```

## Cleanup
```bash
terraform destroy \
  -var="proxmox_endpoint=https://pve:8006" \
  -var="proxmox_api_token=root@pam!token=secret" \
  -var="template_vm_id=9000"
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
| <a name="module_vm"></a> [vm](#module\_vm) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_proxmox_api_token"></a> [proxmox\_api\_token](#input\_proxmox\_api\_token) | Proxmox API token. | `string` | n/a | yes |
| <a name="input_proxmox_endpoint"></a> [proxmox\_endpoint](#input\_proxmox\_endpoint) | Proxmox API endpoint URL. | `string` | n/a | yes |
| <a name="input_proxmox_insecure"></a> [proxmox\_insecure](#input\_proxmox\_insecure) | Skip TLS verification. | `bool` | `false` | no |
| <a name="input_template_vm_id"></a> [template\_vm\_id](#input\_template\_vm\_id) | VM ID of the template to clone from. | `number` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_vm_ids"></a> [vm\_ids](#output\_vm\_ids) | Map of VM names to Proxmox VM IDs. |
| <a name="output_vm_ipv4"></a> [vm\_ipv4](#output\_vm\_ipv4) | Map of VM names to IPv4 addresses reported by the QEMU guest agent. |
<!-- END_TF_DOCS -->
