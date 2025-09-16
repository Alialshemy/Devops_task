resource "aws_vpc_endpoint" "this" {
  
  for_each = var.endpoints
  vpc_id            = var.vpc_id
  service_name      = local.service_names[each.key]
  vpc_endpoint_type = each.value

  security_group_ids =each.value == "Interface" ? var.security_group_ids : [] 
  subnet_ids         = each.value == "Interface" ? var.subnet_ids : []
  route_table_ids    = each.value == "Gateway" ? var.route_table_ids : []
  private_dns_enabled = each.value == "Interface" ? true : false
  
  tags = {
          "Name" = each.key
        }
  
}
