variable "cluster_name" {
  type    = string
  default = "testing-cluster"
}

variable "cidr_block" {
  default     = "10.0.0.0/16"
  type        = string
  description = "CIDR Block for the VPC"
}

variable "region" {
  default     = "ca-central-1"
  type        = string
  description = "Default AWS region for deployment"
}

variable "public_subnet_count" {
  default     = "3"
  type        = string
  description = "Number of public subnets created"
}
