variable "vpc_name" {
  description = "Name of the VPC and prefix for all resources."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_name)) > 0 && length(var.vpc_name) <= 255
    error_message = "vpc_name must be between 1 and 255 characters."
  }
}

variable "cidr_block" {
  description = "Primary CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to associate with the VPC."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.secondary_cidr_blocks : can(cidrnetmask(cidr))])
    error_message = "secondary_cidr_blocks must only contain valid IPv4 CIDR blocks."
  }
}

variable "availability_zones" {
  description = "List of availability zones for subnets."
  type        = list(string)
  default     = []
}

# Subnets
variable "public_subnets" {
  description = "List of public subnet CIDR blocks."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.public_subnets : can(cidrnetmask(cidr))])
    error_message = "public_subnets must only contain valid IPv4 CIDR blocks."
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
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.database_subnets : can(cidrnetmask(cidr))])
    error_message = "database_subnets must only contain valid IPv4 CIDR blocks."
  }
}

variable "create_database_subnet_group" {
  description = "Create an RDS subnet group from database subnets."
  type        = bool
  default     = true
}

# Internet Gateway
variable "create_internet_gateway" {
  description = "Create an Internet Gateway for the VPC."
  type        = bool
  default     = true
}

# NAT Gateway
variable "enable_nat_gateway" {
  description = "Create NAT Gateways for private subnet internet access."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs (cost savings, reduced HA)."
  type        = bool
  default     = false
}

# VPC Flow Logs
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs."
  type        = bool
  default     = false
}

variable "flow_logs_destination" {
  description = "Flow logs destination: cloud-watch-logs or s3."
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_logs_destination)
    error_message = "flow_logs_destination must be cloud-watch-logs or s3."
  }
}

variable "flow_logs_retention_days" {
  description = "CloudWatch Logs retention in days for flow logs."
  type        = number
  default     = 14

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_logs_retention_days)
    error_message = "flow_logs_retention_days must be a valid CloudWatch Logs retention value."
  }
}

variable "flow_logs_traffic_type" {
  description = "Traffic type to capture: ACCEPT, REJECT, or ALL."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "flow_logs_traffic_type must be ACCEPT, REJECT, or ALL."
  }
}

variable "flow_logs_s3_bucket_arn" {
  description = "S3 bucket ARN for flow logs (required when destination is s3)."
  type        = string
  default     = null
}

# VPC Endpoints
variable "enable_s3_endpoint" {
  description = "Create a gateway VPC endpoint for S3."
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "Create a gateway VPC endpoint for DynamoDB."
  type        = bool
  default     = false
}

# DNS
variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

# EKS/ELB Tags
variable "public_subnet_tags" {
  description = "Additional tags for public subnets (e.g., for EKS/ELB discovery)."
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets (e.g., for EKS/ELB discovery)."
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets."
  type        = map(string)
  default     = {}
}

# Resource-specific tags
variable "internet_gateway_tags" {
  description = "Additional tags for the Internet Gateway."
  type        = map(string)
  default     = {}
}

variable "nat_gateway_tags" {
  description = "Additional tags for NAT Gateways."
  type        = map(string)
  default     = {}
}

variable "route_table_tags" {
  description = "Additional tags for route tables."
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags for the VPC."
  type        = map(string)
  default     = {}
}

# Deprecated - keeping for backwards compatibility
variable "subnet_tags" {
  description = "DEPRECATED: Use public_subnet_tags, private_subnet_tags, or database_subnet_tags instead."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
