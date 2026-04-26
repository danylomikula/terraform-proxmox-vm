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
<!-- END_TF_DOCS -->
