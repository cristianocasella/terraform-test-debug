variable "cluster_name" {
  type    = string
  default = "testing-cluster"
}

variable "region" {
  description = "AWS region to be used for Terraform Test"
  type        = string
  default     = "ca-central-1"
}
