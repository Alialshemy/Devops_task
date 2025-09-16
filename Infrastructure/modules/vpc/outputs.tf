output "vpc_id" {
    value = aws_vpc.vpc.id
}
output "public_subnets" {
    value = aws_subnet.public_subnet[*].id
}
output "private_subnets" {
    value = aws_subnet.private_subnet[*].id
}
output "private_subnet_1" {
    value = aws_subnet.private_subnet[0].id
}
output "private_subnet_2" {
    value = aws_subnet.private_subnet[1].id
}
output "private_subnet_3" {
    value = try(aws_subnet.private_subnet[2].id, null)
}

output "private_route_tables" {
    value = aws_route_table.rtb_priv[*].id
}