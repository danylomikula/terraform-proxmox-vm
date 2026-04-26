# Hybrid Cloud-Init Example

## Purpose
This example demonstrates mixed cloud-init modes in one module call:
- File-based cloud-init for one VM.
- Inline cloud-init for another VM.

It also shows shared NIC defaults with per-VM VLAN overrides.

## What It Creates
- One downloaded image resource:
  - `rocky-10-generic-cloud-base.qcow2` (`content_type = "import"`)
- Two VMs:
  - `docker-01` (file-based cloud-init)
  - `docker-02` (inline cloud-init + meta-data hostname override)
- Shared NIC defaults:
  - `bridge = vmbr2`
  - `model = virtio`
- Per-VM VLAN:
  - `docker-01`: `20`
  - `docker-02`: `30`
- Generated SSH keys for both VMs
- QEMU agent enabled
- RNG source `/dev/urandom`

## Cloud-Init Modes
### docker-01
- `user_data_file`
- `network_data_file`
- `meta_data_file`

### docker-02
- Inline `dns`
- Inline `ip_config`
- Inline `user_account`
- `meta_data_file` for `local-hostname`

## Prerequisites
- Proxmox VE API access.
- Datastore `local` exists and has `snippets` enabled.
- Datastore `local-lvm` exists for VM disks.
- Cloud-init files exist under:
  - `cloud-init/docker-01/`
  - `cloud-init/docker-02/`

## Usage
```bash
cd examples/hybrid-cloud-init

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
