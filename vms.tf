/* VIRTUAL MACHINEs */

# jumphosts

resource "aws_key_pair" "sshkey-gen" {
	key_name = "${var.sshkey_name}"
	public_key = "${file("${var.sshkey_path}")}"
}

resource "aws_instance" "vm-jh1" {
	ami						= "${var.ami}"
	instance_type = "${var.jh-size}"

	key_name = "${var.sshkey_name}"
	associate_public_ip_address = true

} 

resource "aws_instance" "vm-jh2" {
	ami						= "${var.ami}"
	instance_type = "${var.jh-size}"

	key_name = "${var.sshkey_name}"
	associate_public_ip_address = true

} 

/* OUTPUT - IPs */
output "NIC-jh1" {
	value = "${aws_instance.vm-jh1.public_ip}"
}

output "NIC-jh2" {
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

resource "aws_autoscaling_group" "asg-web" {
  name                 = "web-"
  launch_configuration = "${aws_launch_configuration.lc-web.name}"
	vpc_zone_identifier       = ["${aws_subnet.sn-pub1.id}", "${aws_subnet.sn-pub2.id}"]
  min_size             = 1
  max_size             = 2

  lifecycle {
    create_before_destroy = true
  }
}
