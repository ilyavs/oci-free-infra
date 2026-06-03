# Free-tier safeguard: hard-limit to 1 instance, 4 OCPUs, 24 GB
locals {
  effective_count = var.free_tier_safeguard ? min(var.instance_count, 1) : var.instance_count
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_ocid
}

# Latest Ubuntu ARM image (for Ampere A1)
data "oci_core_images" "this" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Latest Ubuntu x86 image (for AMD E2 Micro)
data "oci_core_images" "amd" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  image_id = data.oci_core_images.this.images[0].id
}

# ── Network (only if not using existing VCN) ──────────────────────────────

resource "oci_core_vcn" "this" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_ocid
  display_name   = "${var.instance_name}-vcn"
  cidr_blocks    = [var.vcn_cidr]
  dns_label      = replace(var.instance_name, "-", "")
}

resource "oci_core_internet_gateway" "this" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_ocid
  vcn_id         = var.use_existing_vcn ? var.existing_vcn_id : oci_core_vcn.this[0].id
  display_name   = "${var.instance_name}-igw"
}

resource "oci_core_route_table" "this" {
  count          = var.use_existing_vcn ? 0 : 1
  compartment_id = var.compartment_ocid
  vcn_id         = var.use_existing_vcn ? var.existing_vcn_id : oci_core_vcn.this[0].id
  display_name   = "${var.instance_name}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = var.use_existing_vcn ? null : oci_core_internet_gateway.this[0].id
  }
}

resource "oci_core_subnet" "this" {
  count             = var.use_existing_vcn ? 0 : 1
  compartment_id    = var.compartment_ocid
  vcn_id            = var.use_existing_vcn ? var.existing_vcn_id : oci_core_vcn.this[0].id
  display_name      = "${var.instance_name}-subnet"
  cidr_block        = var.subnet_cidr
  route_table_id    = var.use_existing_vcn ? null : oci_core_route_table.this[0].id
  security_list_ids = [oci_core_security_list.this[0].id]
  dns_label         = "public"
}

locals {
  vcn_id    = var.use_existing_vcn ? var.existing_vcn_id : oci_core_vcn.this[0].id
  subnet_id = var.use_existing_vcn ? var.existing_subnet_id : oci_core_subnet.this[0].id
}

# ── Security list ──────────────────────────────────────────────────────────

resource "oci_core_security_list" "this" {
  count          = 1
  compartment_id = var.compartment_ocid
  vcn_id         = local.vcn_id
  display_name   = "${var.instance_name}-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  dynamic "ingress_security_rules" {
    for_each = var.allowed_ssh_cidrs
    content {
      protocol = "6" # TCP
      source   = ingress_security_rules.value
      tcp_options {
        min = 22
        max = 22
      }
    }
  }
}

# ── Instance ───────────────────────────────────────────────────────────────

resource "oci_core_instance" "this" {
  count               = local.effective_count
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[var.availability_domain_index].name
  display_name        = var.instance_name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gb
  }

  source_details {
    source_type               = "image"
    source_id                 = local.image_id
    boot_volume_size_in_gbs   = var.boot_volume_size_gb
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = local.subnet_id
    display_name     = "${var.instance_name}-vnic"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }

  lifecycle {
    ignore_changes = [
      source_details[0].boot_volume_size_in_gbs,
      metadata,
    ]
  }
}

# ── AMD Micro instance (always-free, different AD pool) ────────────────────

resource "oci_core_instance" "amd" {
  count               = var.allow_amd_micro ? 2 : 0
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[var.amd_availability_domain_index].name
  display_name        = "${var.instance_name}-amd-${count.index}"

  shape               = "VM.Standard.E2.1.Micro"

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.amd.images[0].id
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = local.subnet_id
    display_name     = "${var.instance_name}-amd-vnic-${count.index}"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }

  lifecycle {
    ignore_changes = [
      source_details[0].source_id,
      metadata,
    ]
  }
}
