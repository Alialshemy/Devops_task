variable "vpc_id" {
  type        = string
}

variable "region" {
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
}

variable "security_group_ids" {
  type        = list(string)
}

variable "route_table_ids" {
  type        = list(string)
}

variable "endpoints" {
  type        = map(string)
}
