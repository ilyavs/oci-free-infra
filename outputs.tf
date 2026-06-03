output "instance_public_ip" {
  description = "Public IP of the Ampere A1 instance"
  value       = oci_core_instance.this[*].public_ip
}

output "amd_public_ip" {
  description = "Public IPs of the AMD E2.1.Micro instances"
  value       = oci_core_instance.amd[*].public_ip
}

output "ssh_amd" {
  description = "SSH commands for AMD micro instances"
  value = [
    for i, inst in oci_core_instance.amd :
    format("ssh -i %s ubuntu@%s", local.ssh_key, inst.public_ip)
  ]
}

locals {
  ssh_key = var.ssh_private_key_path != "" ? var.ssh_private_key_path : trimsuffix(var.ssh_public_key_path, ".pub")
}

output "ssh_connect" {
  description = "SSH command for the Ampere instance"
  value = length(oci_core_instance.this) > 0 ? format(
    "ssh -i %s ubuntu@%s",
    local.ssh_key,
    oci_core_instance.this[0].public_ip
  ) : null
}
