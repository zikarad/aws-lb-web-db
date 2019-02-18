/* --- VPCs */
resource "aws_vpc" "vpc-lb-web" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name  = "lb-web"
    stage = "poc"
    creator = "terraform"
  }
}

/* ENDPOINTS */
resource "aws_vpc_endpoint" "endp-s3" {
  vpc_id       = "${aws_vpc.vpc-lb-web.id}"
  service_name = "com.amazonaws.${var.region}.s3"
}

resource "aws_vpc_endpoint" "endp-dydb" {
  vpc_id       = "${aws_vpc.vpc-lb-web.id}"
  service_name = "com.amazonaws.${var.region}.dynamodb"
}

resource "aws_vpc_endpoint_route_table_association" "vpcea-s3-pub" {
  vpc_endpoint_id = "${aws_vpc_endpoint.endp-s3.id}"
  route_table_id  = "${aws_route_table.rt-pub.id}"
}

resource "aws_vpc_endpoint_route_table_association" "vpcea-s3-priv" {
  count = "${var.az_count}"
  vpc_endpoint_id = "${aws_vpc_endpoint.endp-s3.id}"
  route_table_id  = "${element(aws_route_table.rt-priv.*.id, count.index)}"
}

resource "aws_vpc_endpoint_route_table_association" "vpcea-dydb-priv" {
  count = "${var.az_count}"
  vpc_endpoint_id = "${aws_vpc_endpoint.endp-dydb.id}"
  route_table_id  = "${element(aws_route_table.rt-priv.*.id, count.index)}"
}

/* NETWORKS */
resource "aws_subnet" "sn-pub" {
  count = "${var.az_count}"

  vpc_id = "${aws_vpc.vpc-lb-web.id}"

  cidr_block        = "${var.pub_nets[count.index]}"
  availability_zone = "${var.az_names[count.index]}"

  tags {
    Name  = "public${count.index}"
    creator = "terraform"
    stage = "poc"
  }
}

resource "aws_subnet" "sn-priv" {
  count = "${var.az_count}"

  vpc_id = "${aws_vpc.vpc-lb-web.id}"

  cidr_block        = "${var.priv_nets[count.index]}"
  availability_zone = "${var.az_names[count.index]}"

  tags {
    Name  = "private${count.index}"
    creator = "terraform"
    stage = "poc"
  }
}

/* GATEWAYs */
resource "aws_internet_gateway" "igw-main" {
  vpc_id = "${aws_vpc.vpc-lb-web.id}"

  tags {
    Name = "igw-main"
    creator = "terraform"
  }
}

resource "aws_vpn_gateway" "vpngw-main" {
  vpc_id = "${aws_vpc.vpc-lb-web.id}"

  tags {
    Name = "vpngw-main"
    creator = "terraform"
  }
}

resource "aws_eip" "eip-ngw" {
  count = "${var.az_count}"
  vpc = true
  depends_on = ["aws_internet_gateway.igw-main"]
}

resource "aws_nat_gateway" "ngw-priv" {
  count = "${var.az_count}"
  allocation_id = "${element(aws_eip.eip-ngw.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.sn-priv.*.id, count.index)}"

  tags {
    Name = "NATgw${count.index+1}"
    creator = "terraform"
  }
}

/* ROUTE TABLEs */
resource "aws_route_table" "rt-pub" {
  vpc_id = "${aws_vpc.vpc-lb-web.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw-main.id}"
  }
}

resource "aws_route_table" "rt-priv" {
  count  = "${var.az_count}" 
  vpc_id = "${aws_vpc.vpc-lb-web.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.ngw-priv.*.id, count.index)}"
  }
}

/* ROUTE TABLE ASSOCIATION */
resource "aws_route_table_association" "rta-pub" {
  count  = "${var.az_count}" 
  subnet_id      = "${element(aws_subnet.sn-pub.*.id, count.index)}"
  route_table_id = "${aws_route_table.rt-pub.id}"
}

resource "aws_route_table_association" "rta-priv" {
  count  = "${var.az_count}" 
  subnet_id      = "${element(aws_subnet.sn-priv.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.rt-priv.*.id, count.index)}"
}
