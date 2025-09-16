################################################################################
# VPC
################################################################################

variable "vpc_name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
  type        = string
  default     = "10.0.0.0/16"
}

################################################################################
# Publiс Subnets
################################################################################

variable "public_subnets_cidr" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "public_subnet_names" {
  description = "Explicit values to use in the Name tag on public subnets. If empty, Name tags are generated"
  type        = list(string)
  default     = []
}

################################################################################
# Private Subnets
################################################################################

variable "private_subnets_cidr" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "create_nate_gateway" {}

variable "public_route_table_routes" {
  default = {}
}
variable "virtual_private_gateway_routes" {
  default = {}
}

variable "create_vpc_peering_route" {
  default = false
}
variable "vpc_peering_cidr" {
  default = ""
}

variable "vpc_peering_connection_id" {
  default = ""
}
variable "network_interface_routes" {
  default = {}
}

variable "map_public_ip_on_launch" {}
####################################################################
# Tags
####################################################################

variable "tags" {
  default = {}
}
variable "vpc_tags" {
  default = {}
}

variable "igw_tags" {
  default = {}
}
variable "private_subnet_tags" {
  default = {}
}
variable "public_subnet_tags" {
  default = {}
}
variable "public_route_table_tags" {
  default = {}
}
variable "elastic_ips_tags" {
  default = {}
}

variable "private_route_table_tags" {
  default = {}
}
variable "nat_gateway_tags" {
  default = {}

}

