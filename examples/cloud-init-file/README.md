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
<!-- END_TF_DOCS -->
