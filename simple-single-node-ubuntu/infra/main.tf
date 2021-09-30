# Define Terraform provider
terraform {
  required_version = ">= 0.12"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~>0.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://ansible@${var.location}/system"
}

resource "random_pet" "hostname" {}

resource "libvirt_network" "lab2-tf_network" {
  name      = "lab2-tf"
  mode      = "bridge"
  bridge    = "bridge99"
  autostart = true
}

resource "libvirt_pool" "kvm_tf" {
  name = "kvm_tf"
  type = "dir"
  path = var.kvm_tf_pool_path
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "ubuntu_2104_qcow2" {
  name   = "ubuntu_2104_qcow2"
  pool   = libvirt_pool.kvm_tf.name
  source = "https://cloud-images.ubuntu.com/releases/hirsute/release/ubuntu-21.04-server-cloudimg-amd64-disk-kvm.img"
  format = "qcow2"
}
resource "libvirt_volume" "vm-disk" {
  name           = "master.qcow2"
  base_volume_id = libvirt_volume.ubuntu_2104_qcow2.id
  pool           = libvirt_pool.kvm_tf.name
  size           = "21474836480"
}
data "template_file" "network_config" {
  template = file("${path.module}/../user_data/network_config_dhcp.cfg")
}

# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  user_data = templatefile("${path.module}/../user_data/cloud_init.cfg", {
    myhostname = "${random_pet.hostname.id}"
  })
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.kvm_tf.name
}

# Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  name       = random_pet.hostname.id
  memory     = "2048"
  vcpu       = 2
  autostart  = true
  qemu_agent = true

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_id = libvirt_network.lab2-tf_network.id
    # wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.vm-disk.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# IPs: use wait_for_lease true or after creation use terraform refresh and terraform show for the ips of domain

/* output "ips" {
  value = libvirt_domain.domain-ubuntu.network_interface.0.addresses
} */

output "hostname" {
  value = random_pet.hostname.id
}