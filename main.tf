resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags =         {
      Name = "${var.vpcname}-vpc"
    }
}

data "aws_availability_zones" "availability_zones" {
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnets)
  cidr_block        = element(var.private_subnets, count.index)
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.availability_zones.names[count.index]
  tags = {
      Name = "private-${var.vpcname}"
    }
}

resource "aws_route_table" "private_route_tables" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "private_routes" {
  count                  = length(var.private_subnets)
  route_table_id         = element(aws_route_table.private_route_tables.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_gws.*.id, count.index)
  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "private_rt_association" {
  count          = length(var.private_subnets)
  route_table_id = element(aws_route_table.private_route_tables.*.id, count.index)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnets)
  cidr_block        = element(var.public_subnets, count.index)
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.availability_zones.names[count.index]

  tags =  {
      "Name" = "public-${var.vpcname}"
    }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  count          = length(var.public_subnets)
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_nat_gateway" "nat_gws" {
  count         = length(var.public_subnets)
  allocation_id = element(aws_eip.nat_ips.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnets.*.id, count.index)
}

resource "aws_eip" "nat_ips" {
  count = length(var.public_subnets)
  vpc   = true
}
