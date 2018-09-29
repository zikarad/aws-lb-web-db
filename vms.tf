/* VIRTUAL MACHINEs */

# jumphosts

resource "aws_key_pair" "sshkey-gen" {
	key_name = "${var.sshkey_name}"
	public_key = "${file("${var.sshkey_path}")}"
}

resource "aws_security_group" "sg-jumphost" {
  vpc_id = "${aws_vpc.vpc-main.id}"

  ingress {
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
