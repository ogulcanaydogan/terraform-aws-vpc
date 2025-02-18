
#### **7. Add Example Usage (`examples/basic-usage/main.tf`)**  
```hcl
module "vpc" {
  source     = "../../"
  region     = "us-east-1"
  cidr_block = "10.0.0.0/16"
  vpc_name   = "example-vpc"
}
