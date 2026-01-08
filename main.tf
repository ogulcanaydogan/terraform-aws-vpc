locals {
  common_tags = merge(var.tags, { Name = var.vpc_name })

  # Subnet configurations
  public_subnet_configs = [
    for index, cidr in var.public_subnets : {
      cidr = cidr
      az   = element(var.availability_zones, index)
    }
  ]

  private_subnet_configs = [
    for index, cidr in var.private_subnets : {
      cidr = cidr
      az   = element(var.availability_zones, index)
    }
  ]

  database_subnet_configs = [
    for index, cidr in var.database_subnets : {
      cidr = cidr
      az   = element(var.availability_zones, index)
    }
  ]

  # NAT Gateway logic
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0
  nat_gateway_azs   = var.enable_nat_gateway ? (var.single_nat_gateway ? [0] : range(length(var.public_subnets))) : []
}

data "aws_region" "current" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(local.common_tags, var.vpc_tags)
}

# Secondary CIDR blocks
resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  for_each = toset(var.secondary_cidr_blocks)

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  count = var.create_internet_gateway && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, var.internet_gateway_tags, {
    Name = "${var.vpc_name}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each = { for index, cfg in local.public_subnet_configs : index => cfg }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, var.subnet_tags, var.public_subnet_tags, {
    Name = "${var.vpc_name}-public-${each.value.az}"
    Tier = "public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each = { for index, cfg in local.private_subnet_configs : index => cfg }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(local.common_tags, var.subnet_tags, var.private_subnet_tags, {
    Name = "${var.vpc_name}-private-${each.value.az}"
    Tier = "private"
  })
}

# Database Subnets
resource "aws_subnet" "database" {
  for_each = { for index, cfg in local.database_subnet_configs : index => cfg }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(local.common_tags, var.subnet_tags, var.database_subnet_tags, {
    Name = "${var.vpc_name}-database-${each.value.az}"
    Tier = "database"
  })
}

# Database Subnet Group
resource "aws_db_subnet_group" "database" {
  count = length(var.database_subnets) > 0 && var.create_database_subnet_group ? 1 : 0

  name        = "${var.vpc_name}-db-subnet-group"
  description = "Database subnet group for ${var.vpc_name}"
  subnet_ids  = [for key in sort(keys(aws_subnet.database)) : aws_subnet.database[key].id]

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-db-subnet-group"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  count = length(aws_subnet.public) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, var.route_table_tags, {
    Name = "${var.vpc_name}-public"
  })
}

resource "aws_route" "public_internet" {
  count = length(aws_internet_gateway.this) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

# NAT Gateway EIPs
resource "aws_eip" "nat" {
  for_each = toset([for i in local.nat_gateway_azs : tostring(i)])

  domain = "vpc"

  tags = merge(local.common_tags, var.nat_gateway_tags, {
    Name = "${var.vpc_name}-nat-eip-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

# NAT Gateways
resource "aws_nat_gateway" "this" {
  for_each = toset([for i in local.nat_gateway_azs : tostring(i)])

  subnet_id         = aws_subnet.public[tonumber(each.key)].id
  allocation_id     = aws_eip.nat[each.key].id
  connectivity_type = "public"

  tags = merge(local.common_tags, var.nat_gateway_tags, {
    Name = "${var.vpc_name}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

# Private Route Tables
resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, var.route_table_tags, {
    Name = "${var.vpc_name}-private-${each.key}"
  })
}

resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateway ? aws_subnet.private : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.this["0"].id : aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Database Route Tables (isolated, no internet access)
resource "aws_route_table" "database" {
  count = length(var.database_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, var.route_table_tags, {
    Name = "${var.vpc_name}-database"
  })
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[0].id
}

# VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination == "cloud-watch-logs" ? 1 : 0

  name              = "/aws/vpc-flow-logs/${var.vpc_name}"
  retention_in_days = var.flow_logs_retention_days

  tags = local.common_tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination == "cloud-watch-logs" ? 1 : 0

  name = "${var.vpc_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination == "cloud-watch-logs" ? 1 : 0

  name = "${var.vpc_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.main.id
  traffic_type             = var.flow_logs_traffic_type
  log_destination_type     = var.flow_logs_destination
  log_destination          = var.flow_logs_destination == "cloud-watch-logs" ? aws_cloudwatch_log_group.flow_logs[0].arn : var.flow_logs_s3_bucket_arn
  iam_role_arn             = var.flow_logs_destination == "cloud-watch-logs" ? aws_iam_role.flow_logs[0].arn : null
  max_aggregation_interval = 60

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-flow-logs"
  })
}

# VPC Endpoints
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    length(aws_route_table.public) > 0 ? [aws_route_table.public[0].id] : [],
    [for rt in aws_route_table.private : rt.id],
    length(aws_route_table.database) > 0 ? [aws_route_table.database[0].id] : []
  )

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    length(aws_route_table.public) > 0 ? [aws_route_table.public[0].id] : [],
    [for rt in aws_route_table.private : rt.id],
    length(aws_route_table.database) > 0 ? [aws_route_table.database[0].id] : []
  )

  tags = merge(local.common_tags, {
    Name = "${var.vpc_name}-dynamodb-endpoint"
  })
}
