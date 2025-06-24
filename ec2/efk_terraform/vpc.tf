resource "aws_vpc" "vpc" {
  cidr_block = var.cidr

  tags = {
    Name = "${var.name_prefix} - VPC"
  }
}

resource "aws_subnet" "subnet" {
  for_each = toset(var.azs)

  availability_zone = join("", [var.region, each.value])
  cidr_block        = cidrsubnet(var.cidr, index(each.value), 8)
  vpc_id            = aws_vpc.vpc.id

  tags = {
    Name = "${var.name_prefix} - Subnet ${upper(each.value)}"
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