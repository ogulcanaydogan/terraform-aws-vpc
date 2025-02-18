# terraform-aws-vpc

A Terraform module to create an AWS VPC.

## Usage

```hcl
module "vpc" {
  source     = "ogulcanaydogan/vpc/aws"
  region     = "us-east-1"
  cidr_block = "10.0.0.0/16"
  vpc_name   = "my-vpc"
}
