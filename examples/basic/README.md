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
<!-- END_TF_DOCS -->
