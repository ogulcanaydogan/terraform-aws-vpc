terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  common_tags = merge(
    {
      Name = var.vpc_name
    },
    var.tags,
  )

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
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.common_tags
}

resource "aws_internet_gateway" "this" {
  count = var.create_internet_gateway && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, var.internet_gateway_tags)
}

resource "aws_subnet" "public" {
  for_each = { for index, cfg in local.public_subnet_configs : index => cfg }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, var.subnet_tags, {
    Name = "${var.vpc_name}-public-${each.key}"
  })
}

resource "aws_subnet" "private" {
  for_each = { for index, cfg in local.private_subnet_configs : index => cfg }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(local.common_tags, var.subnet_tags, {
    Name = "${var.vpc_name}-private-${each.key}"
  })
}

resource "aws_route_table" "public" {
  count = length(aws_subnet.public) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = aws_internet_gateway.this

    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = route.value.id
    }
  }

  tags = merge(local.common_tags, var.route_table_tags, {
    Name = "${var.vpc_name}-public"
  })
}

locals {
  public_route_table_id = try(aws_route_table.public[0].id, null)
}

resource "aws_route_table_association" "public" {
  for_each = local.public_route_table_id == null ? {} : aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = local.public_route_table_id
}

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway ? aws_subnet.public : {}

  domain = "vpc"

  tags = merge(local.common_tags, var.nat_gateway_tags, {
    Name = "${var.vpc_name}-nat-eip-${each.key}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = var.enable_nat_gateway ? aws_subnet.public : {}

  subnet_id         = each.value.id
  allocation_id     = aws_eip.nat[each.key].id
  connectivity_type = "public"

  tags = merge(local.common_tags, var.nat_gateway_tags, {
    Name = "${var.vpc_name}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [each.key] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[route.value].id
    }
  }

  tags = merge(local.common_tags, var.route_table_tags, {
    Name = "${var.vpc_name}-private-${each.key}"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
