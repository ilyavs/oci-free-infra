variable "region" {
  description = "OCI region. Use one with Ampere A1 availability (us-ashburn-1, eu-frankfurt-1, etc.)"
  type        = string
}

variable "user_ocid" {
  description = "OCID of your OCI user"
  type        = string
}

variable "tenancy_ocid" {
  description = "OCID of your tenancy"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID of the compartment to deploy into"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of your OCI API key"
  type        = string
}

variable "private_key_path" {
  description = "Path to your OCI API private key PEM file"
  type        = string
}

variable "instance_name" {
  description = "Display name for the instance"
  type        = string
  default     = "free-tier-arm"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key file (e.g. ~/.ssh/id_rsa.pub)"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to your SSH private key file (e.g. ~/.ssh/id_rsa). Defaults to ssh_public_key_path with .pub stripped."
  type        = string
  default     = ""
}

variable "availability_domain_index" {
  description = "Index into the list of availability domains (0, 1, 2). Try different values if you hit 'Out of host capacity'."
  type        = number
  default     = 0

  validation {
    condition     = var.availability_domain_index >= 0 && var.availability_domain_index < 3
    error_message = "availability_domain_index must be 0, 1, or 2."
  }
}

variable "instance_ocpus" {
  description = "Number of OCPUs"
  type        = number
  default     = 4

  validation {
    condition     = var.instance_ocpus >= 1 && var.instance_ocpus <= 4
    error_message = "Free tier max is 4 OCPUs total across all instances."
  }
}

variable "instance_memory_gb" {
  description = "Memory in GB"
  type        = number
  default     = 24

  validation {
    condition     = var.instance_memory_gb >= 1 && var.instance_memory_gb <= 24
    error_message = "Free tier max is 24 GB total across all instances."
  }
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_gb >= 1 && var.boot_volume_size_gb <= 200
    error_message = "Free tier includes 200 GB total boot volume across all instances."
  }
}

variable "instance_count" {
  description = "Number of instances (hard-limited to 1 when free_tier_safeguard is true)"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1
    error_message = "Must create at least 1 instance."
  }
}

variable "free_tier_safeguard" {
  description = "When true, enforces free-tier limits and prevents >1 instance"
  type        = bool
  default     = true
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "use_existing_vcn" {
  description = "Set to true if you want to use an existing VCN instead of creating one"
  type        = bool
  default     = false
}

variable "existing_vcn_id" {
  description = "OCID of existing VCN (required if use_existing_vcn = true)"
  type        = string
  default     = null
}

variable "existing_subnet_id" {
  description = "OCID of existing public subnet (required if use_existing_vcn = true)"
  type        = string
  default     = null
}

variable "allow_amd_micro" {
  description = "Set true to also provision a free-tier AMD E2.1.Micro instance (1/8 OCPU, 1 GB)"
  type        = bool
  default     = false
}

variable "amd_availability_domain_index" {
  description = "AD index for the AMD micro instance (0/1/2). Micro shapes often only exist in 1 AD per region."
  type        = number
  default     = 0

  validation {
    condition     = var.amd_availability_domain_index >= 0 && var.amd_availability_domain_index < 3
    error_message = "Must be 0, 1, or 2."
  }
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH (default: 0.0.0.0/0 — restrict in production)"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.allowed_ssh_cidrs) > 0
    error_message = "At least one CIDR block is required for SSH access."
  }
}
