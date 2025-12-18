# terraform-aws-vpc

A Terraform module that provisions an AWS VPC with optional public and private subnets, an Internet Gateway, and NAT Gateways.

## Usage

Copy and paste the example below into your configuration or see [`examples/basic`](examples/basic) for a runnable sample.

```hcl
provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "ogulcanaydogan/vpc/aws"
  version = "~> 0.1.0"

  vpc_name            = "example-vpc"
  cidr_block          = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b"]
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway  = true
  create_internet_gateway = true

  tags = {
    Environment = "example"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| availability_zones | List of availability zones to place public and private subnets. | `list(string)` | `[]` | no |
| cidr_block | VPC CIDR block | `string` | n/a | yes |
| create_internet_gateway | When true, create an Internet Gateway for the VPC. | `bool` | `true` | no |
| enable_nat_gateway | When true, create a NAT Gateway for each AZ to serve private subnets. | `bool` | `false` | no |
| internet_gateway_tags | Additional tags applied to the Internet Gateway. | `map(string)` | `{}` | no |
| nat_gateway_tags | Additional tags applied to created NAT Gateways. | `map(string)` | `{}` | no |
| private_subnets | List of private subnet CIDR blocks. | `list(string)` | `[]` | no |
| public_subnets | List of public subnet CIDR blocks. | `list(string)` | `[]` | no |
| route_table_tags | Additional tags applied to created route tables. | `map(string)` | `{}` | no |
| subnet_tags | Additional tags applied to created subnets. | `map(string)` | `{}` | no |
| tags | A map of tags to apply to all supported resources. | `map(string)` | `{}` | no |
| vpc_name | Name of the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| igw_id | ID of the Internet Gateway attached to the VPC |
| nat_gateway_ids | IDs of the created NAT Gateways |
| private_subnet_ids | IDs of the created private subnets |
| public_subnet_ids | IDs of the created public subnets |
| vpc_id | The ID of the created VPC |
