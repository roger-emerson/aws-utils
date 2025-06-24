resource "aws_vpc" "vpc" {
  cidr_block = var.cidr

  tags = {
    Name = "${var.name_prefix} - VPC"
  }
}

resource "aws_subnet" "subnet" {
  for_each = toset(var.azs)

  availability_zone = join("", [data.aws_region.current.name, each.value])
  cidr_block        = cidrsubnet(var.cidr, 2, index(var.azs, each.value))
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "${var.name_prefix} - Subnet ${upper(each.value)}"
  }
}

resource "aws_default_route_table" "rtb" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = {
    Name = "${var.name_prefix} - Route Table MAIN"
  }
}

resource "aws_default_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix} - Default SG"
  }
}

resource "aws_default_network_acl" "nacl" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.name_prefix} - Default NACL"
  }
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name_prefix} - Route Table"
  }
}

resource "aws_route_table_association" "rtb-assoc" {
  for_each = toset(var.azs)

  subnet_id      = aws_subnet.subnet[each.value].id
  route_table_id = aws_route_table.rtb.id
}