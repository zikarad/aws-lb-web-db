variable "ami" {
# Only EU-CENTRAL-1
default = "ami-0fe525d17aa2b4240"
}

variable "project"  { default = "lb-web" }
variable "stage"    { default = "poc"    }

variable "region"   {	default = "eu-central-1" }

variable "vpc_cidr" { default = "10.1.0.0/16" }

variable "az_names" {
    type = "list"
    default = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "pub_nets" {
	type = "list"
  default = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
}

variable "priv_nets" {
	type = "list"
  default = ["10.1.128.0/24", "10.1.129.0/24", "10.1.130.0/24"]
}

variable "az_count"      { default = 2 }
variable "web_count_min" { default = 2 }
variable "web_count_max" { default = 6 }

variable "jh-size"  { default = "t3.micro" }
variable "web-size" {	default = "t3.micro" }
variable "db-size"  { default = "db.t3.micro" }

variable "web_server_port" { default = 80 }
variable "lb_port"     { default = 80 }
variable "spot-price"  { default = "0.02" }
variable "sshkey_name" { default = "azure-test1" }

variable "dbstorage_type" { default = "gp2" }
variable "dbstorage_size" { default = "10"  }

variable "sshkey_path" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "route53zone" {}
variable "myiprange" {}
variable "db_username" {}
variable "db_password" {}
variable "db_dbname" {}
variable "db_port" { default = "5432" }
