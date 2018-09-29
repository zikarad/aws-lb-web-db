variable "ami" {
# Only EU-CENTRAL-1
default = "ami-0fe525d17aa2b4240"
}

variable "region" {
	default = "eu-central-1"
}

variable "jh-size" {
	default = "t2.micro"
}

variable "web-size" {
	default = "t2.micro"
}

variable "sshkey_name" {
	default = "azure-test1"
}

variable "sshkey_path" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}