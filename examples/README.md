# VM Module Examples

This directory contains runnable examples for the Proxmox VM Terraform module.

## Examples

| Example | Description |
|---------|-------------|
| [basic](./basic) | Minimal VM that boots from an existing Ubuntu installer ISO attached as CD-ROM. |
| [clone](./clone) | Clone a VM from an existing Proxmox template VM ID. |
| [cloud-init](./cloud-init) | Inline cloud-init with SSH key generation and Rocky Linux 10 image download. |
| [cloud-init-file](./cloud-init-file) | File-based cloud-init snippets with SSH key placeholder replacement and Rocky Linux 10 image download. |
| [hybrid-cloud-init](./hybrid-cloud-init) | Mixed mode: one VM with file-based cloud-init and another with inline cloud-init. |
| [complete](./complete) | Full multi-VM composition with image download, multi-disk, multi-NIC, and rich outputs. |

## Run an Example

```bash
cd <example-directory>
terraform init
terraform plan \
  -var="proxmox_endpoint=https://pve:8006" \
  -var="proxmox_api_token=root@pam!token=secret"
terraform apply \
  -var="proxmox_endpoint=https://pve:8006" \
  -var="proxmox_api_token=root@pam!token=secret"
```

For `clone`, also provide:

```bash
-var="template_vm_id=9000"
```

## Clean Up

```bash
terraform destroy \
  -var="proxmox_endpoint=https://pve:8006" \
  -var="proxmox_api_token=root@pam!token=secret"
```

## Notes

- Read each example's local `README.md` for exact prerequisites and outputs.
- File-based cloud-init examples require snippet-capable datastore (for example `local` with `snippets` enabled).
- The `basic` example expects the Ubuntu ISO to already exist in Proxmox storage.
