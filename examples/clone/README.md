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
<!-- END_TF_DOCS -->
