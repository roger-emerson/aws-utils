module "vpc1" {
  source = "./vpc"

  azs         = ["a", "b"]
  cidr        = "10.100.100.0/23"
  name_prefix = "Lab"
}

terraform {
  backend "s3" {
    bucket         = "emersonlabs-terraform-state"
    key            = "ec2/efk_terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}