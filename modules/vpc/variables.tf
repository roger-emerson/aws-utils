variable "azs" {
  type = list(string)
}

variable "cidr" {
  type = string
}

variable "name_prefix" {
  type = string
}


variable "vpc_cidr" {}
variable "subnet_cidr" {}
variable "availability_zone" {}
variable "name_prefix" {}
variable "tags" {
  type = map(string)
}