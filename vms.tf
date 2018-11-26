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

resource "aws_security_group" "sg-elb-web" {
	name = "web-lb"

	ingress {
		from_port   = 80
		to_port     = 80
		protocol    = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port   = 0
		to_port     = 0
		protocol    = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	tags {
		Name = "sg-web_elb-http"
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

output "dns_name-web_elb" {
	value = "${aws_elb.web-elb.dns_name}"
}

# web asg/lb
resource "aws_elb" "web-elb" {
	name = "webha"
	availability_zones = [""]
	security_groups = ["aws_security_group.sg-elb-web.id"]

	listener {
		lb_port           = 80
		lb_protocol       = "http"
		instance_port     = "${var.web_server_port}"
		instance_protocol = "tcp"
	}

	health_check {
		healthy_threshold   = 2
		unhealthy_threshold = 2
		timeout   = 3
		interval  = 30
		target = "HTTP:${var.web_server_port}/index.html"
	}
}

resource "aws_launch_configuration" "lc-web" {
  name          = "web"
  image_id      = "${var.ami}"
  instance_type = "${var.web-size}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg-web" {
	name                 = "web-asg"
	min_size             = 1
	max_size             = 2
	health_check_grace_period = 300
	health_check_type    = "ELB"
	desired_capacity     = 4
	force_delete         = true
	launch_configuration = "${aws_launch_configuration.lc-web.name}"
	vpc_zone_identifier  = ["${aws_subnet.sn-pub1.id}", "${aws_subnet.sn-pub2.id}"]

	load_balancers		 = ["${aws_elb.web-elb.name}"]

  lifecycle {
    create_before_destroy = true
  }
}
