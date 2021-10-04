# Define Terraform provider
terraform {
  required_version = ">= 0.12"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">=0.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://ansible@${var.location}/system"
}

module "my_network" {
  source        = "srb3/network/libvirt"
  name          = "${var.location}-tf"
  mode          = "bridge"
  bridge_device = "bridge99"
  autostart     = "true"
}

module "my_pool" {
  source = "srb3/pool/libvirt"
  name   = "default"
  path   = "/data/virt/pools/kvm_tf_pool"
}

module "my-domain" {
  source     = "srb3/domain/libvirt"
  os_name    = "ubuntu"
  os_version = "20.10"
  memory     = 2048
  vcpu       = 2
  autostart  = true
  network    = "${var.location}-tf"
  user_cloudinit = templatefile("./templates/cloud_init.cfg", {
    hostname       = "tf-kvm-test"
    user           = "ansible"
    ssh_public_key = chomp(file("~/.ssh/id_rsa.pub"))
  })
}
