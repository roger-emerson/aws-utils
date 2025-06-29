variable "my_ip_cidr" {
  description = "Your public IP address with CIDR mask (e.g. 203.0.113.1/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_pair" {
  description = "ssh keypair for instances"
  type        = string
  default     = "terraform"
}

variable "ami_id" {
  description = "ami id"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}
