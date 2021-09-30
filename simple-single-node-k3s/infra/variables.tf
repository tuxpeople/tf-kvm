variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  type        = string
  default     = "test"
}
variable "location" {
  description = "KVM server"
  default     = "lab2"
}

variable "kvm_tf_pool_path" {
  description = "path of the 'kvm_tf' pool"
  default     = "/data/virt/pools/kvm_tf_pool"
}