resource "aws_security_group" "sg-dbaccess" {
  name        = "rds-access"
  description = ""
  vpc_id      = "${aws_vpc.vpc-lb-web.id}"

  ingress {
    from_port   = "${var.db_port}"
    to_port     = "${var.db_port}"
    protocol    = "-1"
    cidr_blocks = ["${var.priv_nets}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = ["${aws_subnet.sn-priv.*.id}"]

  tags = {
    Name = "DB subnet"
  }
}


resource "aws_db_instance" "masterdb" {
  allocated_storage    = 10
  storage_type         = "gp2"
  db_subnet_group_name = "${aws_db_subnet_group.default.name}"
# vps_securty_group_ids = []
  skip_final_snapshot  = true

  engine            = "postgres"
  engine_version    = "10.6"
  instance_class    = "db.t3.micro"
  name              = "${var.db_dbname}"

  username          = "${var.db_username}"
  password          = "${var.db_password}"
}
