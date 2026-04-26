# Cloud-Init Example

## Purpose
This example demonstrates inline cloud-init with automatic SSH key generation, using a Rocky Linux 10 cloud image downloaded by the `download-file` module.

## What It Creates
- One downloaded image resource:
  - `rocky-10-generic-cloud-base.qcow2` (`content_type = "import"`)
- One VM: `docker-01`
- Disk imported from the downloaded Rocky image
- One NIC on `vmbr2`, model `virtio`, VLAN `20`
- Inline cloud-init:
  - DNS domain: `lab.local`
  - DNS servers: `1.1.1.1`, `8.8.8.8`
  - IPv4: `10.20.0.20/16`
  - Gateway: `10.20.0.1`
  - Username: `admin`
- Generated SSH key pair saved locally

## Prerequisites
- Proxmox VE API access.
- Datastore `local` allows downloaded image storage.
- Datastore `local-zfs` exists for VM disks.

## Usage
```bash
cd examples/cloud-init

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
