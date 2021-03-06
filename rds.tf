resource "aws_security_group" "sg-dbaccess" {
  name        = "rds-access"
  description = "access to DB port"
  vpc_id      = "${aws_vpc.vpc-lb-web.id}"

  ingress {
    description = "local acces to DB"
    from_port   = "${var.db_port}"
    to_port     = "${var.db_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.priv_nets}"]
  }

  egress {
    description = "any out allow"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "DB access (${var.db_port})"
    project = "${var.project}"
    creator = "Terraform"
    stage   = "${var.stage}"
  }
}

resource "aws_db_subnet_group" "priv_nets" {
  name        = "private_nets"
  description = "private networks"
  subnet_ids  = ["${aws_subnet.sn-priv.*.id}"]

  tags = {
    Name    = "DB priv sn"
    project = "${var.project}"
    creator = "Terraform"
    stage   = "${var.stage}"
  }
}

resource "aws_db_instance" "masterdb" {
  identifier_prefix      = "${var.project}-"
  allocated_storage      = "${var.dbstorage_size}"
  storage_type           = "${var.dbstorage_type}"
  db_subnet_group_name   = "${aws_db_subnet_group.priv_nets.name}"
  vpc_security_group_ids = ["${aws_security_group.sg-dbaccess.id}"]
  skip_final_snapshot    = true

  instance_class = "${var.db-size}"
  engine         = "postgres"
  engine_version = "10.6"
  auto_minor_version_upgrade = true
  
  name           = "${var.db_dbname}"
  username = "${var.db_username}"
  password = "${var.db_password}"

  tags {
    Name     = "masterdb"
    project  = "${var.project}"
    creator  = "terraform"
    stage    = "${var.stage}"
  }
}

output "RDS hostname/endpoint" {
  value = "${aws_db_instance.masterdb.address}"
}
