variable "location" {
  description = "KVM server"
  default     = "lab2"
}

variable "kvm_tf_pool_path" {
  description = "path of the 'kvm_tf' pool"
  default     = "/data/virt/pools/kvm_tf_pool"
}