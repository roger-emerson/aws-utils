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
resource "aws_security_group" "harvester" {
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

resource "aws_security_group" "rancher" {
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

resource "aws_eip" "harvester_vip" {}

resource "aws_eip" "rancher" {}

resource "aws_instance" "harvester1" {
  ami                    = var.ami_id # Amazon Linux 2
  instance_type          = "m5.large"
  subnet_id              = module.vpc.subnet_id
  private_ip             = "10.100.100.101"
  key_name               = var.key_pair
  vpc_security_group_ids = [aws_security_group.harvester.id]
  tags = {
    Name = "hv1.emersonlabs.net"
  }
}

resource "aws_instance" "harvester2" {
  ami                    = var.ami_id
  instance_type          = "m5.large"
  subnet_id              = module.vpc.subnet_id
  private_ip             = "10.100.100.102"
  key_name               = var.key_pair
  vpc_security_group_ids = [aws_security_group.harvester.id]
  tags = {
    Name = "hv2.emersonlabs.net"
  }
}

resource "aws_instance" "rancher" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = module.vpc.subnet_id
  private_ip             = "10.100.100.105"
  key_name               = var.key_pair
  vpc_security_group_ids = [aws_security_group.rancher.id]
  tags = {
    Name = "rancher.emersonlabs.net"
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

output "harvester_public_ip" {
  value = aws_eip.harvester_vip.public_ip
}

output "rancher_public_ip" {
  value = aws_eip.rancher.public_ip
}