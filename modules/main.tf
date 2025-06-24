module "vpc1" {
  source = "./vpc"

  azs         = ["a", "b"]
  cidr        = "10.100.100.0/23"
  name_prefix = "Lab"
}