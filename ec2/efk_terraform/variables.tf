variable "azs" {
  type    = list(string)
  default = ["a", "b"]
}

variable "cidr" {
  type    = string
  default = "192.168.0.0/16"
}

variable "name_prefix" {
  type    = string
  default = "Lab"
}

variable "region" {
  type    = string
  default = "us-east-1"
}
