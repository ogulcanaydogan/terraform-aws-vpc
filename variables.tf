variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to place public and private subnets."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.public_subnets) == 0 && length(var.private_subnets) == 0 ? true : length(var.availability_zones) >= max(length(var.public_subnets), length(var.private_subnets))
    error_message = "availability_zones must be provided when defining public or private subnets and must be at least as long as the subnet lists."
  }
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.public_subnets : can(cidrnetmask(cidr))])
    error_message = "public_subnets must only contain valid IPv4 CIDR blocks."
  }

  validation {
    condition     = length(var.public_subnets) == 0 || length(var.public_subnets) == length(var.availability_zones)
    error_message = "public_subnets length must match availability_zones length when provided."
  }

  validation {
    condition     = length(var.public_subnets) == 0 || var.create_internet_gateway
    error_message = "public_subnets require create_internet_gateway to be true."
  }
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.private_subnets : can(cidrnetmask(cidr))])
    error_message = "private_subnets must only contain valid IPv4 CIDR blocks."
  }

  validation {
    condition     = length(var.private_subnets) == 0 || length(var.private_subnets) == length(var.availability_zones)
    error_message = "private_subnets length must match availability_zones length when provided."
  }
}

variable "enable_nat_gateway" {
  description = "When true, create a NAT Gateway for each AZ to serve private subnets."
  type        = bool
  default     = false

  validation {
    condition     = var.enable_nat_gateway == false || (length(var.private_subnets) > 0 && length(var.public_subnets) == length(var.private_subnets) && length(var.availability_zones) > 0 && var.create_internet_gateway)
    error_message = "enable_nat_gateway requires private_subnets, an equal number of public_subnets, availability_zones, and an Internet Gateway."
  }
}

variable "create_internet_gateway" {
  description = "When true, create an Internet Gateway for the VPC."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to apply to all supported resources."
  type        = map(string)
  default     = {}
}

variable "route_table_tags" {
  description = "Additional tags applied to created route tables."
  type        = map(string)
  default     = {}
}

variable "subnet_tags" {
  description = "Additional tags applied to created subnets."
  type        = map(string)
  default     = {}
}

variable "nat_gateway_tags" {
  description = "Additional tags applied to created NAT Gateways."
  type        = map(string)
  default     = {}
}

variable "internet_gateway_tags" {
  description = "Additional tags applied to the Internet Gateway."
  type        = map(string)
  default     = {}
}
