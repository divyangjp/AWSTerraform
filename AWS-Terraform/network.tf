
locals {
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}

# Create vpc
resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr}"

  tags = {
    Name = "${var.env}-ctest-vpc"
    env = "${var.env}"
    resource_group = "${var.rgroup}"
  }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.env}-ctest-igw"
    env = "${var.env}"
    resource_group = "${var.rgroup}"
  }
}

# NAT Elastic IP
resource "aws_eip" "nat_eip" {
  vpc = true
  depends_on = [aws_internet_gateway.igw]
}

# NAT Gateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id = "${element(aws_subnet.public_subnet.*.id, 0)}"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "ctest-nat"
    env = "${var.env}"
    resource_group = "${var.rgroup}"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  count = "${length(var.public_subnets_cidr)}"
  cidr_block = "${element(var.public_subnets_cidr, count.index)}"
  availability_zone = "${element(local.availability_zones, count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-${element(local.availability_zones, count.index)}-pub-subnet"
    env = "${var.env}"
    resource_group = "${var.rgroup}"
    type = "Public"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  count  = "${length(var.private_subnets_cidr)}"
  cidr_block = "${element(var.private_subnets_cidr, count.index)}"
  availability_zone = "${element(local.availability_zones, count.index)}"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.env}-${element(local.availability_zones, count.index)}-priv-subnet"
    env = "${var.env}"
    resource_group = "${var.rgroup}"
    type = "Private"
  }
}

# Routing table for private subnet
resource "aws_route_table" "private_rtable" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.env}-priv-route-table"
    env = "${var.env}"
    resource_group = "${var.rgroup}"
  }
}

# Routing table for public subnet
resource "aws_route_table" "public_rtable" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.env}-public-route-table"
    env = "${var.env}"
    resource_group = "${var.rgroup}"
  }
}

resource "aws_route" "route_to_igw" {
  route_table_id = "${aws_route_table.public_rtable.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.igw.id}"
}

resource "aws_route" "route_to_natgw" {
  route_table_id = "${aws_route_table.private_rtable.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.natgw.id}"
}

# Associate route tables
resource "aws_route_table_association" "public" {
  count = "${length(var.public_subnets_cidr)}"
  subnet_id = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_rtable.id}"
}

resource "aws_route_table_association" "private" {
  count = "${length(var.private_subnets_cidr)}"
  subnet_id = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private_rtable.id}"
}

# Default security group for VPC
resource "aws_security_group" "default" {
  name = "${var.env}-default-sg"
  description = "Default security group"
  vpc_id = "${aws_vpc.vpc.id}"
  depends_on = [aws_vpc.vpc]

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }

  tags = {
    env = "${var.env}"
    resource_group = "${var.rgroup}"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "${var.env}-allow-ssh"
  description = "Allow ssh inbound traffic"
  vpc_id = "${aws_vpc.vpc.id}"
  depends_on = [aws_vpc.vpc]

  ingress {
    description = "ssh from anywhere"
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
    Name = "allow_ssh"
    env = var.env
  }
}

resource "aws_security_group" "allow_ssh_in_vpc" {
  name        = "${var.env}-allow-ssh-in-vpc"
  description = "Allow ssh inbound traffic"
  vpc_id = "${aws_vpc.vpc.id}"
  depends_on = [aws_vpc.vpc]

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_in_vpc"
    env = var.env
  }
}
