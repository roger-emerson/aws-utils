# Set S3 and DynamoDB config for cross-platform work
terraform {
  backend "s3" {
    bucket         = "emersonlabs-terraform-state"
    key            = "ec2/harvester/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source            = "../../modules/rj-vpc"
  vpc_cidr          = "10.100.100.0/28"
  subnet_cidr       = "10.100.100.0/28"
  availability_zone = "us-east-1a"
  name_prefix       = "hv"
  igw               = true

  tags = {
    Environment = "dev"
  }
}

resource "aws_eip" "harvester_vip" {
  vpc = true
}

resource "aws_eip" "rancher" {
  vpc = true
}

resource "aws_network_interface" "harvester1_eni" {
  subnet_id       = module.vpc.private_subnets[0]
  private_ips     = ["10.100.100.101"]
  security_groups = [aws_security_group.harvester_sg.id]
}

resource "aws_network_interface" "harvester2_eni" {
  subnet_id       = module.vpc.private_subnets[0]
  private_ips     = ["10.100.100.102"]
  security_groups = [aws_security_group.harvester_sg.id]
}

resource "aws_network_interface" "rancher_eni" {
  subnet_id       = module.vpc.private_subnets[0]
  private_ips     = ["10.100.100.105"]
  security_groups = [aws_security_group.rancher_sg.id]
}

resource "aws_instance" "harvester1" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type = "m5.large"
  key_name      = var.key_pair
  network_interface {
    network_interface_id = aws_network_interface.harvester1_eni.id
    device_index         = 0
  }
  tags = {
    Name = "harvester-node-1"
  }
}

resource "aws_instance" "harvester2" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "m5.large"
  key_name      = var.key_pair
  network_interface {
    network_interface_id = aws_network_interface.harvester2_eni.id
    device_index         = 0
  }
  tags = {
    Name = "harvester-node-2"
  }
}

resource "aws_instance" "rancher" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.medium"
  key_name      = var.key_pair
  network_interface {
    network_interface_id = aws_network_interface.rancher_eni.id
    device_index         = 0
  }
  tags = {
    Name = "rancher-server"
  }
}

resource "aws_eip_association" "harvester_eip_association" {
  instance_id   = aws_instance.harvester1.id
  allocation_id = aws_eip.harvester_vip.id
}

resource "aws_eip_association" "rancher_eip_association" {
  instance_id   = aws_instance.rancher.id
  allocation_id = aws_eip.rancher.id
}

resource "aws_security_group" "harvester_sg" {
  name        = "harvester-sg"
  description = "Allow HTTP, HTTPS, and SSH"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rancher_sg" {
  name        = "rancher-sg"
  description = "Allow HTTPS and SSH"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "harvester_public_ip" {
  value = aws_eip.harvester_vip.public_ip
}

output "rancher_public_ip" {
  value = aws_eip.rancher.public_ip
}