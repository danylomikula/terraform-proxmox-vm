# Cloud-Init File Example

## Purpose
This example demonstrates file-based cloud-init with snippet uploads, automatic SSH key placeholder replacement, and a Rocky Linux 10 cloud image downloaded by the `download-file` module.

## What It Creates
- One downloaded image resource:
  - `rocky-10-generic-cloud-base.qcow2` (`content_type = "import"`)
- One VM: `docker-01`
- Disk imported from the downloaded Rocky image
- One NIC on `vmbr2` with VLAN `20`
- File-based cloud-init:
  - `user_data_file`
  - `network_data_file`
  - `meta_data_file`
- Generated SSH key pair:
  - Public key replaces `{{ssh_public_key}}` in user-data
- QEMU agent enabled
- RNG source `/dev/urandom`

## Prerequisites
- Proxmox VE API access.
- Datastore `local` exists and has `snippets` content type enabled.
- Datastore `local-zfs` exists for VM disks.
- Cloud-init files exist:
  - `cloud-init/docker-01/user-data.yml`
  - `cloud-init/docker-01/network-data.yml`
  - `cloud-init/docker-01/meta-data.yml`

## Usage
```bash
cd examples/cloud-init-file

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
| <a name="module_vm"></a> [vm](#module\_vm) | ../.. | n/a |

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
| <a name="output_ssh_key_files"></a> [ssh\_key\_files](#output\_ssh\_key\_files) | Map of VM names to local file paths of generated SSH private keys. |
| <a name="output_vm_ids"></a> [vm\_ids](#output\_vm\_ids) | Map of VM names to Proxmox VM IDs. |
| <a name="output_vm_ipv4"></a> [vm\_ipv4](#output\_vm\_ipv4) | Map of VM names to IPv4 addresses reported by the QEMU guest agent. |
<!-- END_TF_DOCS -->
