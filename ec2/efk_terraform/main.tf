# EFK Stack Terraform Configuration

# Set S3 and DynamoDB config for cross-platform work
terraform {
  backend "s3" {
    bucket         = "emersonlabs-terraform-state"
    key            = "ec2/efk_terraform/terraform.tfstate"
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
  name_prefix       = "efk"
  
  tags = {
    Environment = "dev"
  }
}

resource "aws_security_group" "efk" {
  name        = "efk-sg"
  description = "Allow EFK components to communicate"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.100.100.0/28"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  ami_id = "ami-0c2b8ca1dad447f8a" # Amazon Linux 2 AMI in us-east-1
}

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH access from your IP"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "bastion" {
  ami                         = local.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.subnet_id
  private_ip                  = "10.100.100.5"
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = "terraform"
  associate_public_ip_address = true
  tags = {
    Name = "bastion.emersonlabs.net"
  }
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
}

resource "aws_instance" "elasticsearch" {
  ami                         = local.ami_id
  instance_type               = "t3.small"
  subnet_id                   = module.vpc.subnet_id
  private_ip                  = "10.100.100.10"
  vpc_security_group_ids      = [aws_security_group.efk.id]
  key_name                    = "terraform"
  associate_public_ip_address = false
  tags = {
    Name = "elasticsearch.emersonlabs.net"
  }
  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user_data.log|logger -t user-data -s 2>/dev/console) 2>&1
              yum update -y
              yum install docker -y
              systemctl start docker
              docker run -d --name elasticsearch -p 9200:9200 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:8.13.0
              EOF
}

resource "aws_instance" "kibana" {
  ami                         = local.ami_id
  instance_type               = "t3.small"
  subnet_id                   = module.vpc.subnet_id
  private_ip                  = "10.100.100.11"
  vpc_security_group_ids      = [aws_security_group.efk.id]
  key_name                    = "terraform"
  associate_public_ip_address = false
  tags = {
    Name = "kibana.emersonlabs.net"
  }
  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user_data.log|logger -t user-data -s 2>/dev/console) 2>&1
              yum update -y
              yum install docker -y
              systemctl start docker
              docker run -d --name kibana -p 5601:5601 -e ELASTICSEARCH_HOSTS=http://10.100.100.10:9200 docker.elastic.co/kibana/kibana:8.13.0
              EOF
}

resource "aws_instance" "fluentd" {
  ami                         = local.ami_id
  instance_type               = "t3.small"
  subnet_id                   = module.vpc.subnet_id
  private_ip                  = "10.100.100.12"
  vpc_security_group_ids      = [aws_security_group.efk.id]
  key_name                    = "terraform"
  associate_public_ip_address = false
  tags = {
    Name = "fluentd.emersonlabs.net"
  }
  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user_data.log|logger -t user-data -s 2>/dev/console) 2>&1
              yum update -y
              yum install docker -y
              systemctl start docker
              docker run -d --name fluentd -p 24224:24224 -p 24224:24224/udp fluent/fluentd:v1.16-1
              EOF
}