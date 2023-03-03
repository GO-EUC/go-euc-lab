# Create a VPC
# resource "aws_vpc" "example" {
#   cidr_block = "10.0.0.0/16"
# }

resource "aws_vpc" "avp_vpc" {
  cidr_block           = "10.67.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "avp_public_subnet_1" {
  vpc_id                  = aws_vpc.avp_vpc.id
  cidr_block              = "10.67.11.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"
}

resource "aws_subnet" "avp_public_subnet_2" {
  vpc_id                  = aws_vpc.avp_vpc.id
  cidr_block              = "10.67.12.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1b"
}

resource "aws_subnet" "avp_private_subnet_1" {
  vpc_id                  = aws_vpc.avp_vpc.id
  cidr_block              = "10.67.21.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-west-1a"
}

resource "aws_subnet" "avp_private_subnet_2" {
  vpc_id                  = aws_vpc.avp_vpc.id
  cidr_block              = "10.67.22.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-west-1b"
}

resource "aws_internet_gateway" "avp_internet_gateway" {
  vpc_id = aws_vpc.avp_vpc.id
}

resource "aws_eip" "avp_eip_nat1" {
  depends_on = [aws_internet_gateway.avp_internet_gateway]
}

resource "aws_nat_gateway" "avp_nat_gateway" {
  allocation_id = aws_eip.avp_eip_nat1.id
  subnet_id     = aws_subnet.avp_public_subnet_1.id

  depends_on = [aws_internet_gateway.avp_internet_gateway]
}

resource "aws_default_route_table" "avp_default_rt" {
  default_route_table_id = aws_vpc.avp_vpc.default_route_table_id
}

resource "aws_route" "avp_default_route" {
  route_table_id         = aws_default_route_table.avp_default_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.avp_nat_gateway.id
}


resource "aws_route_table" "avp_public_rt" {
  vpc_id = aws_vpc.avp_vpc.id
}

resource "aws_route" "avp_default_public_route" {
  route_table_id         = aws_route_table.avp_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.avp_internet_gateway.id
}

resource "aws_route_table_association" "avp_public_rt_assoc" {
  subnet_id      = aws_subnet.avp_public_subnet_1.id
  route_table_id = aws_route_table.avp_public_rt.id
}