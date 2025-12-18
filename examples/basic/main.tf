module "vpc" {
  source = "../.."

  vpc_name            = "example-vpc"
  cidr_block          = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b"]
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway  = true

  tags = {
    Environment = "example"
  }
}

