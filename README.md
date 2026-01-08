# terraform-aws-vpc

Terraform module that creates an AWS VPC with public, private, and database subnets, NAT Gateways, VPC endpoints, and flow logs.

## Features

- **Three subnet tiers** - Public, private, and database subnets
- **Single NAT Gateway** - Cost-saving option for non-production environments
- **VPC Flow Logs** - CloudWatch Logs or S3 destination
- **VPC Endpoints** - S3 and DynamoDB gateway endpoints
- **Database subnet group** - Automatic RDS subnet group creation
- **EKS/ELB tags** - Subnet tags for Kubernetes service discovery
- **Secondary CIDRs** - Associate additional CIDR blocks

## Usage

### Basic VPC

```hcl
module "vpc" {
  source = "ogulcanaydogan/vpc/aws"

  vpc_name           = "my-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "production"
  }
}
```

### With Database Subnets

```hcl
module "vpc" {
  source = "ogulcanaydogan/vpc/aws"

  vpc_name           = "app-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  create_database_subnet_group = true
  enable_nat_gateway           = true

  tags = {
    Environment = "production"
  }
}
```

### Single NAT Gateway (Cost Savings)

```hcl
module "vpc" {
  source = "ogulcanaydogan/vpc/aws"

  vpc_name           = "dev-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true  # Uses one NAT for all AZs

  tags = {
    Environment = "development"
  }
}
```

### With VPC Flow Logs

```hcl
module "vpc" {
  source = "ogulcanaydogan/vpc/aws"

  vpc_name           = "secure-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true

  # Flow Logs to CloudWatch
  enable_flow_logs         = true
  flow_logs_destination    = "cloud-watch-logs"
  flow_logs_retention_days = 30
  flow_logs_traffic_type   = "ALL"

  tags = {
    Environment = "production"
  }
}
```

### With VPC Endpoints

```hcl
module "vpc" {
  source = "ogulcanaydogan/vpc/aws"

  vpc_name           = "endpoint-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true

  # Gateway VPC Endpoints (free)
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  tags = {
    Environment = "production"
  }
}
```

### For EKS Cluster

```hcl
module "vpc" {
  source = "ogulcanaydogan/vpc/aws"

  vpc_name           = "eks-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway = true

  # EKS subnet tags for ALB/NLB discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/my-cluster"          = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/my-cluster"          = "shared"
  }

  tags = {
    Environment = "production"
  }
}
```

### Private Only (No Internet Access)

```hcl
module "vpc" {
  source = "ogulcanaydogan/vpc/aws"

  vpc_name           = "isolated-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  create_internet_gateway = false
  enable_nat_gateway      = false

  # Use VPC endpoints for AWS services
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  tags = {
    Environment = "isolated"
  }
}
```

## Inputs

### Required

| Name | Description | Type |
|------|-------------|------|
| `vpc_name` | Name of the VPC and prefix for resources | `string` |
| `cidr_block` | Primary CIDR block for the VPC | `string` |

### Subnets

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `availability_zones` | List of AZs for subnets | `list(string)` | `[]` |
| `public_subnets` | Public subnet CIDR blocks | `list(string)` | `[]` |
| `private_subnets` | Private subnet CIDR blocks | `list(string)` | `[]` |
| `database_subnets` | Database subnet CIDR blocks | `list(string)` | `[]` |
| `create_database_subnet_group` | Create RDS subnet group | `bool` | `true` |
| `secondary_cidr_blocks` | Additional CIDR blocks | `list(string)` | `[]` |

### Gateways

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_internet_gateway` | Create Internet Gateway | `bool` | `true` |
| `enable_nat_gateway` | Create NAT Gateways | `bool` | `false` |
| `single_nat_gateway` | Use single NAT for all AZs | `bool` | `false` |

### Flow Logs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_flow_logs` | Enable VPC Flow Logs | `bool` | `false` |
| `flow_logs_destination` | Destination (cloud-watch-logs, s3) | `string` | `"cloud-watch-logs"` |
| `flow_logs_retention_days` | CloudWatch retention days | `number` | `14` |
| `flow_logs_traffic_type` | Traffic type (ACCEPT, REJECT, ALL) | `string` | `"ALL"` |
| `flow_logs_s3_bucket_arn` | S3 bucket ARN (when destination is s3) | `string` | `null` |

### VPC Endpoints

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_s3_endpoint` | Create S3 gateway endpoint | `bool` | `false` |
| `enable_dynamodb_endpoint` | Create DynamoDB gateway endpoint | `bool` | `false` |

### DNS

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_dns_support` | Enable DNS support | `bool` | `true` |
| `enable_dns_hostnames` | Enable DNS hostnames | `bool` | `true` |

### Tags

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `tags` | Tags for all resources | `map(string)` | `{}` |
| `vpc_tags` | Additional VPC tags | `map(string)` | `{}` |
| `public_subnet_tags` | Additional public subnet tags | `map(string)` | `{}` |
| `private_subnet_tags` | Additional private subnet tags | `map(string)` | `{}` |
| `database_subnet_tags` | Additional database subnet tags | `map(string)` | `{}` |
| `internet_gateway_tags` | Additional IGW tags | `map(string)` | `{}` |
| `nat_gateway_tags` | Additional NAT Gateway tags | `map(string)` | `{}` |
| `route_table_tags` | Additional route table tags | `map(string)` | `{}` |

## Outputs

### VPC

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `vpc_arn` | VPC ARN |
| `vpc_cidr_block` | Primary CIDR block |

### Subnets

| Name | Description |
|------|-------------|
| `public_subnet_ids` | Public subnet IDs |
| `public_subnet_cidrs` | Public subnet CIDRs |
| `public_subnet_azs` | Public subnet AZs |
| `private_subnet_ids` | Private subnet IDs |
| `private_subnet_cidrs` | Private subnet CIDRs |
| `private_subnet_azs` | Private subnet AZs |
| `database_subnet_ids` | Database subnet IDs |
| `database_subnet_cidrs` | Database subnet CIDRs |
| `database_subnet_azs` | Database subnet AZs |
| `database_subnet_group_name` | RDS subnet group name |
| `database_subnet_group_id` | RDS subnet group ID |

### Gateways

| Name | Description |
|------|-------------|
| `internet_gateway_id` | Internet Gateway ID |
| `nat_gateway_ids` | NAT Gateway IDs |
| `nat_gateway_public_ips` | NAT Gateway public IPs |

### Route Tables

| Name | Description |
|------|-------------|
| `public_route_table_id` | Public route table ID |
| `private_route_table_ids` | Private route table IDs |
| `database_route_table_id` | Database route table ID |

### VPC Endpoints

| Name | Description |
|------|-------------|
| `s3_endpoint_id` | S3 VPC endpoint ID |
| `dynamodb_endpoint_id` | DynamoDB VPC endpoint ID |

### Flow Logs

| Name | Description |
|------|-------------|
| `flow_log_id` | Flow Log ID |
| `flow_log_cloudwatch_log_group_arn` | CloudWatch Log Group ARN |

## Examples

See [`examples/basic`](./examples/basic) for a complete configuration.
