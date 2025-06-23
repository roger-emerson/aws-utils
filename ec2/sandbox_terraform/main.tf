provider "aws" {
  region = "us-east-1" # or your desired region
}

# Add random value
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

# Create a Security Group
resource "aws_security_group" "launch_wizard_1" {
  name        = "launch-wizard-1"
  description = "launch-wizard-1 created 2025-06-20T06:05:53.592Z"
  vpc_id      = "vpc-0786a3d5bc2ea7fc9"

  ingress {
    description = "SSH"
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

  tags = {
    Name = "launch-wizard-1"
  }
}

# Create an EC2 Instance
resource "aws_instance" "example" {
  ami           = "ami-0f3f13f145e66a0a3"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = "subnet-0350629fcf0319671"
  vpc_security_group_ids = [aws_security_group.launch_wizard_1.id]
  key_name = "terraform" 

  # Install & Init docker
  user_data = <<-EOF
              exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
              echo "Starting user_data execution at $(date)"
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo systemctl enable docker
              sudo systemctl start docker
              usermod -aG docker ec2-user
              echo "Docker installation complete at $(date)"
              EOF

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  private_dns_name_options {
    hostname_type                           = "ip-name"
    enable_resource_name_dns_a_record       = true
    enable_resource_name_dns_aaaa_record    = false
  }

  tags = {
    Name = "vm-${random_integer.suffix.result}.emersonlabs.net"
  }
}