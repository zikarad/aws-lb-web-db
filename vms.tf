/* DEFINE DATA */
data "aws_route53_zone" "r53zone" {
  name         = "${var.route53zone}"
  private_zone = false
}

/* VIRTUAL MACHINEs */
# jumphosts
resource "aws_key_pair" "sshkey-gen" {
	key_name   = "${var.sshkey_name}"
	public_key = "${file("${var.sshkey_path}")}"
}

resource "aws_security_group" "sg-jumphost" {
    name   = "ssh access"
    description = "Allow ssh access from myiprange"
    vpc_id = "${aws_vpc.vpc-lb-web.id}"

  ingress {
    description = "SSH from my range"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.myiprange}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name    = "sg-jumphost"
    project = "${var.project}"
	  creator = "terraform"
    stage   = "${var.stage}"
  }
}

resource "aws_security_group" "sg-web" {
  name = "Web access"
  description = "Allow SSH, HTTP and HTTP access"
  vpc_id = "${aws_vpc.vpc-lb-web.id}"

  ingress {
    description = "SSH from jh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

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

  tags {
    Name    = "sg-web-http"
    project = "${var.project}"
	  creator = "terraform"
    stage   = "${var.stage}"
  }
}

resource "aws_security_group" "sg-elb-web" {
  name        = "web-lb"
  description = "Allows http through"
  vpc_id      = "${aws_vpc.vpc-lb-web.id}"

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
		Name    = "sg-web_elb-http"
    project = "${var.project}"
	  creator = "terraform"
    stage   = "${var.stage}"
	}
}

resource "aws_spot_instance_request" "vm-jh" {
  count = "${var.az_count}"

  spot_price           = "${var.spot-price}"
  wait_for_fulfillment = true

  ami             = "${var.ami}"
  instance_type   = "${var.jh-size}"

  subnet_id       = "${element(aws_subnet.sn-pub.*.id, count.index)}"
  security_groups = ["${aws_security_group.sg-jumphost.id}"]
  key_name        = "${var.sshkey_name}"
  associate_public_ip_address = true

  tags {
    Name    = "jh${count.index}"
    project = "${var.project}"
	  creator = "terraform"
    stage   = "${var.stage}"
  }
}

/* DNS mangling */
resource "aws_route53_record" "r53a-jh" {
  count   = "${var.az_count}"

  zone_id = "${data.aws_route53_zone.r53zone.zone_id}"
  name    = "jh${count.index}"
  type    = "A"
  ttl     = 300
  records = ["${element(aws_spot_instance_request.vm-jh.*.public_ip, count.index)}"]
}

resource "aws_route53_record" "r53a-web" {
  zone_id = "${data.aws_route53_zone.r53zone.zone_id}"
  name    = "web"
  type    = "CNAME"

  alias {
    name                   = "${aws_elb.web-elb.dns_name}"
    zone_id                = "${aws_elb.web-elb.zone_id}"
    evaluate_target_health = false
  }
}

/* OUTPUT - IPs */
output "public_ip jumphosts:" {
  value = "${aws_spot_instance_request.vm-jh.*.public_ip}"
}

output "dns_name-web_elb:" {
  value = "${aws_elb.web-elb.dns_name}"
}

# web asg/lb
resource "aws_elb" "web-elb" {
  name = "webha"
  subnets         = ["${aws_subnet.sn-pub.*.id}"]
  security_groups = ["${aws_security_group.sg-elb-web.id}"]

  listener {
    lb_port           = "${var.lb_port}"
    lb_protocol       = "http"
    instance_port     = "${var.web_server_port}"
	  instance_protocol = "http"
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
  name_prefix   = "webha-"
  image_id      = "${var.ami}"
  instance_type = "${var.web-size}"
  spot_price    = "${var.spot-price}"
  security_groups = ["${aws_security_group.sg-web.id}"]
  associate_public_ip_address = false
  key_name = "${var.sshkey_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg-web" {
  name                 = "web-asg"
  min_size             = "${var.web_count_min}"
  max_size             = "${var.web_count_max}"
  health_check_grace_period = 300
  health_check_type    = "ELB"
  desired_capacity     = 2
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.lc-web.name}"
  vpc_zone_identifier  = ["${aws_subnet.sn-pub.*.id}"]

  load_balancers		 = ["${aws_elb.web-elb.name}"]
  lifecycle {
    create_before_destroy = true
  }
}
