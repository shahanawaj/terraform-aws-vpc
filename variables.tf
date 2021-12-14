variable "eks_vpc_cidr_block" {
  type = string
}

variable "eks_private_subnets" {
  type = list(string)
}

variable "eks_public_subnets" {
  type = list(string)
}

variable "cluster_name" {
  type = string
}

