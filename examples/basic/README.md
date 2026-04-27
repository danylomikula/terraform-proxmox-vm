# Basic Example

## Purpose
This example creates a minimal VM and boots it from an existing Ubuntu installer ISO attached as a CD-ROM.

## What It Creates
- One VM: `web-01`
- One disk: `scsi0`, `32G` on `local-zfs`
- One CD-ROM: `ide0` with `ubuntu-24.04.4-live-server-amd64.iso`
- Boot order: `ide0 -> scsi0 -> net0`
- One NIC on `vmbr0`

## Prerequisites
- Proxmox VE API access.
- The ISO file already exists on node `pve`, datastore `local`:
  - `ubuntu-24.04.4-live-server-amd64.iso`

## Usage
```bash
cd examples/basic

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
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.104.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | >= 0.104.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_vm"></a> [vm](#module\_vm) | ../.. | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [proxmox_file.ubuntu_iso](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_proxmox_api_token"></a> [proxmox\_api\_token](#input\_proxmox\_api\_token) | Proxmox API token. | `string` | n/a | yes |
| <a name="input_proxmox_endpoint"></a> [proxmox\_endpoint](#input\_proxmox\_endpoint) | Proxmox API endpoint URL. | `string` | n/a | yes |
| <a name="input_proxmox_insecure"></a> [proxmox\_insecure](#input\_proxmox\_insecure) | Skip TLS verification. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_vm_ids"></a> [vm\_ids](#output\_vm\_ids) | Map of VM names to Proxmox VM IDs. |
| <a name="output_vm_ipv4"></a> [vm\_ipv4](#output\_vm\_ipv4) | Map of VM names to IPv4 addresses reported by the QEMU guest agent. |
<!-- END_TF_DOCS -->
