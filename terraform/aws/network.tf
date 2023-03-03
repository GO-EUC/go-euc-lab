# Create a VPC
# resource "aws_vpc" "example" {
#   cidr_block = "10.0.0.0/16"
# }

resource "aws_vpc" "goeuc_vpc" {
  cidr_block           = "10.67.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
   
  tags = {
    Name = "goeuc_vpc_1"
  }
}

resource "aws_subnet" "goeuc_public_subnet_1" {
  vpc_id                  = aws_vpc.goeuc_vpc.id
  cidr_block              = "10.67.11.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1a"

  tags = {
    Name = "goeuc_public_sn_1"
  }
}

resource "aws_subnet" "goeuc_public_subnet_2" {
  vpc_id                  = aws_vpc.goeuc_vpc.id
  cidr_block              = "10.67.12.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-1b"

  tags = {
    Name = "goeuc_public_sn_2"
  }
}

resource "aws_subnet" "goeuc_private_subnet_1" {
  vpc_id                  = aws_vpc.goeuc_vpc.id
  cidr_block              = "10.67.21.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-west-1a"

  tags = {
    Name = "goeuc_private_sn_1"
  }
}

resource "aws_subnet" "goeuc_private_subnet_2" {
  vpc_id                  = aws_vpc.goeuc_vpc.id
  cidr_block              = "10.67.22.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-west-1b"

  tags = {
    Name = "goeuc_private_sn_2"
  }
}

resource "aws_internet_gateway" "goeuc_internet_gateway" {
  vpc_id = aws_vpc.goeuc_vpc.id

  tags = {
    Name = "goeuc_ig_1"
  }
}

resource "aws_eip" "goeuc_eip_nat1" {
  depends_on = [aws_internet_gateway.goeuc_internet_gateway]

  tags = {
    Name = "goeuc_eip_1"
  }
}

resource "aws_nat_gateway" "goeuc_nat_gateway" {
  allocation_id = aws_eip.goeuc_eip_nat1.id
  subnet_id     = aws_subnet.goeuc_public_subnet_1.id

  depends_on = [aws_internet_gateway.goeuc_internet_gateway]

  tags = {
    Name = "goeuc_ngw_1"
  }
}

resource "aws_default_route_table" "goeuc_default_rt" {
  default_route_table_id = aws_vpc.goeuc_vpc.default_route_table_id

  tags = {
    Name = "goeuc_default_rt_1"
  }
}

resource "aws_route" "goeuc_default_route" {
  route_table_id         = aws_default_route_table.goeuc_default_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.goeuc_nat_gateway.id

}

resource "aws_route_table" "goeuc_public_rt" {
  vpc_id = aws_vpc.goeuc_vpc.id

  tags = {
    Name = "goeuc_public_rt_1"
  }
}

resource "aws_route" "goeuc_default_public_route" {
  route_table_id         = aws_route_table.goeuc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.goeuc_internet_gateway.id

}

resource "aws_route_table_association" "goeuc_public_rt_assoc" {
  subnet_id      = aws_subnet.goeuc_public_subnet_1.id
  route_table_id = aws_route_table.goeuc_public_rt.id
}