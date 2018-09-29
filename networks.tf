/* --- VPCs */
resource "aws_vpc" "vpc-main" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name  = "main"
    stage = "poc"
  }
}

/* ENDPOINTS */
resource "aws_vpc_endpoint" "endp-s3" {
  vpc_id       = "${aws_vpc.vpc-main.id}"
  service_name = "com.amazonaws.${var.region}.s3"
}

resource "aws_vpc_endpoint" "endp-dydb" {
  vpc_id       = "${aws_vpc.vpc-main.id}"
  service_name = "com.amazonaws.${var.region}.dynamodb"
}

/* NETWORKS */
resource "aws_subnet" "sn-pub1" {
  vpc_id = "${aws_vpc.vpc-main.id}"

  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"

  tags {
    Name  = "public1"
    stage = "poc"
  }
}

resource "aws_subnet" "sn-pub2" {
  vpc_id = "${aws_vpc.vpc-main.id}"

  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"

  tags {
    Name  = "public2"
    stage = "poc"
  }
}

resource "aws_subnet" "sn-priv1" {
  vpc_id = "${aws_vpc.vpc-main.id}"

  cidr_block        = "10.0.129.0/24"
  availability_zone = "eu-central-1a"

  tags {
    Name  = "private1"
    stage = "poc"
  }
}

resource "aws_subnet" "sn-priv2" {
  vpc_id = "${aws_vpc.vpc-main.id}"

  cidr_block        = "10.0.130.0/24"
  availability_zone = "eu-central-1b"

  tags {
    Name  = "private2"
    stage = "poc"
  }
}

/* GATEWAYs */
resource "aws_internet_gateway" "igw-main" {
  vpc_id = "${aws_vpc.vpc-main.id}"

  tags {
    Name = "igw-main"
  }
}

resource "aws_vpn_gateway" "vpngw-main" {
  vpc_id = "${aws_vpc.vpc-main.id}"

  tags {
    Name = "main"
  }
}

resource "aws_eip" "eip-ngw1" {
  vpc = true

  depends_on = ["aws_internet_gateway.igw-main"]
}

resource "aws_eip" "eip-ngw2" {
  vpc = true

  depends_on = ["aws_internet_gateway.igw-main"]
}

resource "aws_nat_gateway" "ngw-priv1" {
  allocation_id = "${aws_eip.eip-ngw1.id}"
  subnet_id     = "${aws_subnet.sn-priv1.id}"

  tags {
    Name = "NATgw1"
  }
}

resource "aws_nat_gateway" "ngw-priv2" {
  allocation_id = "${aws_eip.eip-ngw2.id}"
  subnet_id     = "${aws_subnet.sn-priv2.id}"

  tags {
    Name = "NATgw2"
  }
}

/* ROUTE TABLEs */
resource "aws_route_table" "rt-pub" {
  vpc_id = "${aws_vpc.vpc-main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw-main.id}"
  }
}

resource "aws_route_table" "rt-priv1" {
  vpc_id = "${aws_vpc.vpc-main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.ngw-priv1.id}"
  }
}

resource "aws_route_table" "rt-priv2" {
  vpc_id = "${aws_vpc.vpc-main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.ngw-priv2.id}"
  }
}

/* ROUTE TABLE ASSOCIATION */
resource "aws_route_table_association" "rta-pub1" {
  subnet_id      = "${aws_subnet.sn-pub1.id}"
  route_table_id = "${aws_route_table.rt-pub.id}"
}

resource "aws_route_table_association" "rta-pub2" {
  subnet_id      = "${aws_subnet.sn-pub2.id}"
  route_table_id = "${aws_route_table.rt-pub.id}"
}