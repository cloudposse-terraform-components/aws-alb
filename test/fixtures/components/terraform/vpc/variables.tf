variable "region" {
  type        = string
  description = "AWS region."
}

variable "ipv4_primary_cidr_block" {
  type        = string
  description = "The primary IPv4 CIDR block for the VPC."
  default     = "172.16.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zone suffixes (e.g. ['b', 'c'])."
  default     = []
}

variable "subnet_type_tag_key" {
  type        = string
  description = "Key for subnet type tag."
  default     = "cpco.io/subnet/type"
}

variable "public_subnets_enabled" {
  type        = bool
  description = "Whether to create public subnets."
  default     = true
}

variable "max_nats" {
  type        = number
  description = "Unused - accepted for fixture compatibility."
  default     = 0
}

variable "nat_gateway_enabled" {
  type        = bool
  description = "Unused - accepted for fixture compatibility."
  default     = false
}

variable "nat_instance_enabled" {
  type        = bool
  description = "Unused - accepted for fixture compatibility."
  default     = false
}

variable "max_subnet_count" {
  type        = number
  description = "Unused - accepted for fixture compatibility."
  default     = 0
}

variable "vpc_flow_logs_enabled" {
  type        = bool
  description = "Unused - accepted for fixture compatibility."
  default     = false
}
