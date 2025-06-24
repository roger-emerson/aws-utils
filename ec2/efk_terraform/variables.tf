variable "azs" {
  type    = list(string)
  default = ["a", "b"]
}

variable "cidr" {
  type    = string
  default = "10.100.96.0/21"
}

variable "name_prefix" {
  type    = string
  default = "Lab"
}
