variable "azs" {
  type    = list(string)
  default = ["a", "b"]
}

variable "cidr" {
  type    = string
  default = "10.100.100.0/21"
}

variable "ami" {
  type    = string
  default = "ami-0c2b8ca1dad447f8a"
}