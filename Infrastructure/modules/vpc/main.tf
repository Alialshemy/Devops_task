#################################################################################
# VPC Module
#################################################################################

#################################################################################
# DATA
#################################################################################

data "aws_availability_zones" "available" {}

#################################################################################
# VPC
#################################################################################

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = merge(
    { "Name" = var.vpc_name },
    var.tags,
    var.vpc_tags
  )
}

#################################################################################
# Internet GateWay
#################################################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { Name = "${var.vpc_name}-igw" },
    var.tags,
    var.igw_tags,
  )
}

#################################################################################
# Public Subnets
#################################################################################

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.public_subnets_cidr) # Create subnets with number of input list
  cidr_block              = element(var.public_subnets_cidr, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone       = element(data.aws_availability_zones.available.names, count.index) # Each subnet will be in index of az
  #  availability_zone_id    = element(data.aws_availability_zones.available.zone_ids, count.index) # Each subnet will be in index of az
  tags = merge(
    var.tags,
    var.public_subnet_tags,
  { Name = "${var.vpc_name}-public-${element(data.aws_availability_zones.available.names, count.index)}" }) # Ex. VPCTest-public-us-east-1a
  timeouts {}
}

#################################################################################
# Private Subnets
#################################################################################

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc.id
  count  = "${length(var.private_subnets_cidr)}" > 0 && var.create_nate_gateway ? "${length(var.private_subnets_cidr)}" : 0
  cidr_block              = element(var.private_subnets_cidr, count.index)
  map_public_ip_on_launch = false
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = merge(
    var.tags,
    var.private_subnet_tags,
  { Name = "${var.vpc_name}-private-${element(data.aws_availability_zones.available.names, count.index)}" }) #  Ex. VPCTest-private-us-east-1a
  timeouts {}
}

#################################################################################
# Public Routing
#################################################################################

resource "aws_route_table" "rtb_pub" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    { Name = "${var.vpc_name}-public-routetable" },
    var.tags,
    var.public_route_table_tags,
  )
  timeouts {}
}
#################################################################################
# IGW Route in Public Route Table
#################################################################################

resource "aws_route" "igw_route" {
  route_table_id         = aws_route_table.rtb_pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

#################################################################################
# Public Routing table association
#################################################################################
# Will Attach All Public Subnets to one routing table

resource "aws_route_table_association" "rta-subnet_pub" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.rtb_pub.id
}

#################################################################################
# Elastic IPs for Nats
#################################################################################

resource "aws_eip" "eip" {
  count = "${length(var.private_subnets_cidr)}" > 0 && var.create_nate_gateway ? "${length(var.private_subnets_cidr)}" : 0
 # vpc   = true
  tags = merge(
    var.tags,
    var.elastic_ips_tags,
    { Name = "${var.vpc_name}-nat-elastic-ip-${count.index + 1}" }
  )
  timeouts {}
}

#################################################################################
# Create Nat GateWay 
#################################################################################

resource "aws_nat_gateway" "ngw" {
  # Check if create_nate_gateway enabled, will create nat gateways based on number of private subnets
  count         = "${length(var.private_subnets_cidr)}" > 0 && var.create_nate_gateway ? "${length(var.private_subnets_cidr)}" : 0
  allocation_id = element(aws_eip.eip[*].id, count.index)
  subnet_id     = element(aws_subnet.public_subnet[*].id, count.index)
  tags = merge(
    var.tags,
    var.nat_gateway_tags,
    { Name = "${var.vpc_name}-nat-gateway-${count.index + 1}" }
  )
}

#################################################################################
# Create Private route tables for each nat gateway
#################################################################################

resource "aws_route_table" "rtb_priv" {
  count  = "${length(var.private_subnets_cidr)}" > 0 && var.create_nate_gateway ? "${length(var.private_subnets_cidr)}" : 0
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    var.tags,
    var.private_route_table_tags,
    { Name = "${var.vpc_name}-private-routetable-${count.index + 1}" }
  )
  timeouts {}
}

#################################################################################
# Associate private subnets for each private route table
#################################################################################

resource "aws_route_table_association" "rta-subnet_priv" {
  count          = "${length(var.private_subnets_cidr)}" > 0 && var.create_nate_gateway ? "${length(var.private_subnets_cidr)}" : 0
  subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
  route_table_id = element(aws_route_table.rtb_priv[*].id, count.index)
}

#################################################################################
# Update Private Route Tables with Nat GateWays
#################################################################################

resource "aws_route" "nat_gateway" {
  count                  = "${length(var.private_subnets_cidr)}" > 0 && var.create_nate_gateway ? "${length(var.private_subnets_cidr)}" : 0
  route_table_id         = element(aws_route_table.rtb_priv[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.ngw[*].id, count.index)

  timeouts {
    create = "5m"
  }
}

#################################################################################
# Configure Special Routing for Public Table
#################################################################################

# This is conifgured for EgyptVPC
# Adding Virtual Private Gateways for the public routing tables

resource "aws_route" "virtual_private_gateway_trb_pub" {
  for_each = "${length(var.virtual_private_gateway_routes)}" > 0 ? var.virtual_private_gateway_routes : {}
  #count                 = "${length(var.private_subnets_cidr)}" > 0 && var.virtual_private_gateway_routes > 0 && var.create_nate_gateway ? "${length(var.private_subnets_cidr)}" : 0
  route_table_id         = aws_route_table.rtb_pub.id
  destination_cidr_block = each.value.destination_cidr_block
  gateway_id             = each.value.gw_id
}

# Adding VPC Peering  Routes

# Adding VPC Peering for all public routing  tables if vpc peering is exit in VPC
# This Also needed for EgyptProd VPC

resource "aws_route" "vpc_peering_public_route" {
  count                     = var.create_vpc_peering_route ? 1 : 0
  route_table_id            = aws_route_table.rtb_pub.id
  destination_cidr_block    = var.vpc_peering_cidr
  vpc_peering_connection_id = var.vpc_peering_connection_id
}
# 
resource "aws_route" "network_interface_public_route" {
  for_each               = "${length(var.network_interface_routes)}" > 0 ? var.network_interface_routes : {}
  route_table_id         = aws_route_table.rtb_pub.id
  destination_cidr_block = each.value.destination_cidr_block
  network_interface_id   = each.value.network_interface
}
#################################################################################
# Configure Special Routing for Private Tables
#################################################################################

# This assume that there are 3 routing tables for 3 private subnets, this is conifgured for EgyptVPC
# Adding Virtual Private Gateways for the private routing tables

resource "aws_route" "virtual_private_gateway_priv_rt_1" {
  for_each = "${length(var.private_subnets_cidr)}" > 0 && "${length(var.virtual_private_gateway_routes)}" > 0 && var.create_nate_gateway ? var.virtual_private_gateway_routes : {}
  #count            = "${length(var.private_subnets_cidr)}" > 0 && var.virtual_private_gateway_routes > 0 && var.create_nate_gateway ? "${length(var.private_subnets_cidr)}" : 0
  route_table_id         = aws_route_table.rtb_priv[0].id
  destination_cidr_block = each.value.destination_cidr_block
  gateway_id             = each.value.gw_id
}

resource "aws_route" "virtual_private_gateway_priv_rt_2" {
  for_each = "${length(var.private_subnets_cidr)}" > 0 && "${length(var.virtual_private_gateway_routes)}" > 0 && var.create_nate_gateway ? var.virtual_private_gateway_routes : {}
  #count            = "${length(var.private_subnets_cidr)}" > 0 && var.virtual_private_gateway_routes > 0 && var.create_nate_gateway ? "${length(var.private_subnets_cidr)}" : 0
  route_table_id         = aws_route_table.rtb_priv[1].id
  destination_cidr_block = each.value.destination_cidr_block
  gateway_id             = each.value.gw_id

}
resource "aws_route" "virtual_private_gateway_priv_rt_3" {
  for_each = "${length(var.private_subnets_cidr)}" > 0 && "${length(var.virtual_private_gateway_routes)}" > 0 && var.create_nate_gateway ? var.virtual_private_gateway_routes : {}
  #count            = "${length(var.private_subnets_cidr)}" > 0 && var.virtual_private_gateway_routes > 0 && var.create_nate_gateway ? "${length(var.private_subnets_cidr)}" : 0
  route_table_id         = aws_route_table.rtb_priv[2].id
  destination_cidr_block = each.value.destination_cidr_block
  gateway_id             = each.value.gw_id
}

# Adding VPC Peering  Routes

# Adding VPC Peering for all private routing  tables if vpc peering is exit in VPC
# This Also needed for EgyptProd VPC

resource "aws_route" "vpc_peering_private_route" {
  #  for_each = "${length(var.private_subnets_cidr)}" > 0 && "${length(var.virtual_private_gateway_routes)}" > 0 && var.create_nate_gateway ?  var.virtual_private_gateway_routes : {}
  count                     = "${length(var.private_subnets_cidr)}" > 0 && var.create_vpc_peering_route && var.create_nate_gateway ? "${length(var.private_subnets_cidr)}" : 0
  route_table_id            = element(aws_route_table.rtb_priv[*].id, count.index)
  destination_cidr_block    = var.vpc_peering_cidr
  vpc_peering_connection_id = var.vpc_peering_connection_id
}

