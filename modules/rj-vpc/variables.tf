variable "name_prefix" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "subnet_cidr" {
  type = string
}
variable "availability_zone" {
  type = string
}
variable "tags" {
  type = map(string)
}