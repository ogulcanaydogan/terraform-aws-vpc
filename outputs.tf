# VPC
output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "Primary CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

# Internet Gateway
output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = try(aws_internet_gateway.this[0].id, null)
}

# Public Subnets
output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [for key in sort(keys(aws_subnet.public)) : aws_subnet.public[key].id]
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets."
  value       = [for key in sort(keys(aws_subnet.public)) : aws_subnet.public[key].cidr_block]
}

output "public_subnet_azs" {
  description = "Availability zones of the public subnets."
  value       = [for key in sort(keys(aws_subnet.public)) : aws_subnet.public[key].availability_zone]
}

# Private Subnets
output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = [for key in sort(keys(aws_subnet.private)) : aws_subnet.private[key].id]
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets."
  value       = [for key in sort(keys(aws_subnet.private)) : aws_subnet.private[key].cidr_block]
}

output "private_subnet_azs" {
  description = "Availability zones of the private subnets."
  value       = [for key in sort(keys(aws_subnet.private)) : aws_subnet.private[key].availability_zone]
}

# Database Subnets
output "database_subnet_ids" {
  description = "IDs of the database subnets."
  value       = [for key in sort(keys(aws_subnet.database)) : aws_subnet.database[key].id]
}

output "database_subnet_cidrs" {
  description = "CIDR blocks of the database subnets."
  value       = [for key in sort(keys(aws_subnet.database)) : aws_subnet.database[key].cidr_block]
}

output "database_subnet_azs" {
  description = "Availability zones of the database subnets."
  value       = [for key in sort(keys(aws_subnet.database)) : aws_subnet.database[key].availability_zone]
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group."
  value       = try(aws_db_subnet_group.database[0].name, null)
}

output "database_subnet_group_id" {
  description = "ID of the database subnet group."
  value       = try(aws_db_subnet_group.database[0].id, null)
}

# NAT Gateways
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways."
  value       = [for key in sort(keys(aws_nat_gateway.this)) : aws_nat_gateway.this[key].id]
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways."
  value       = [for key in sort(keys(aws_eip.nat)) : aws_eip.nat[key].public_ip]
}

# Route Tables
output "public_route_table_id" {
  description = "ID of the public route table."
  value       = try(aws_route_table.public[0].id, null)
}

output "private_route_table_ids" {
  description = "IDs of the private route tables."
  value       = [for key in sort(keys(aws_route_table.private)) : aws_route_table.private[key].id]
}

output "database_route_table_id" {
  description = "ID of the database route table."
  value       = try(aws_route_table.database[0].id, null)
}

# VPC Endpoints
output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint."
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint."
  value       = try(aws_vpc_endpoint.dynamodb[0].id, null)
}

# Flow Logs
output "flow_log_id" {
  description = "ID of the VPC Flow Log."
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for flow logs."
  value       = try(aws_cloudwatch_log_group.flow_logs[0].arn, null)
}
