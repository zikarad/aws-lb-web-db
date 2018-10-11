/* VIRTUAL MACHINEs */

# jumphosts

resource "aws_key_pair" "sshkey-gen" {
	key_name = "${var.sshkey_name}"
	public_key = "${file("${var.sshkey_path}")}"
}

resource "aws_security_group" "sg-jumphost" {
	name   = "ssh access"
	description = "Allow ssh access from any"
  vpc_id = "${aws_vpc.vpc-main.id}"

  ingress {
		description = "SSH from any"
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

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name = "sg-jumphost"
  }
}

resource "aws_security_group" "sg-web" {
	name = "Web access"
	description = "Allow HTTP and HTTP access from any"
  vpc_id = "${aws_vpc.vpc-main.id}"

  ingress {
		description = "HTTP from any"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

	ingress {
		description = "HTTPS from any"
		from_port   = 443
		to_port     = 443
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name = "sg-web-http"
  }
}

resource "aws_instance" "vm-jh1" {
	ami						= "${var.ami}"
	instance_type = "${var.jh-size}"

	subnet_id			= "${aws_subnet.sn-pub1.id}"
	security_groups = ["${aws_security_group.sg-jumphost.id}"]
	key_name = "${var.sshkey_name}"
	associate_public_ip_address = true

	tags {
		Name = "jh1"
	}
}

resource "aws_instance" "vm-jh2" {
	ami						= "${var.ami}"
	instance_type = "${var.jh-size}"

	subnet_id			= "${aws_subnet.sn-pub2.id}"
	security_groups = ["${aws_security_group.sg-jumphost.id}"]

	key_name = "${var.sshkey_name}"
	associate_public_ip_address = true

	tags {
		Name = "jh2"
	}

}

/* OUTPUT - IPs */
output "public_ip-jh1" {
	value = "${aws_instance.vm-jh1.public_ip}"
}

output "public_ip-jh2" {
	value = "${aws_instance.vm-jh2.public_ip}"
}

# web asg
resource "aws_launch_configuration" "lc-web" {
  name_prefix   = "web-"
  image_id      = "${var.ami}"
  instance_type = "${var.web-size}"

  lifecycle {
    create_before_destroy = true
  }
}

/*
resource "aws_autoscaling_group" "asg-web" {
  name                 = "web-"
  launch_configuration = "${aws_launch_configuration.lc-web.name}"
	vpc_zone_identifier       = ["${aws_subnet.sn-pub1.id}", "${aws_subnet.sn-pub2.id}"]
  min_size             = 1
  max_size             = 2

  lifecycle {
    create_before_destroy = true
  }
} */
