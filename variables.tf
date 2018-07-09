variable "aws_region" {}
variable "aws_profile" {}
variable "vpc_id" {}

variable "instance_role" {
  default = "role-C2E2-ec2s3e2e"
}

variable "kms_key" {
  default = "arn:aws:kms:eu-west-1:854634259953:key/a53056c0-468a-4445-8412-c2366e565201"
}

variable "bucket_name" {}

data "aws_subnet_ids" "private" {
  vpc_id = "${var.vpc_id}"

  tags {
    "airbus:network" = "private"
  }
}

data "aws_subnet_ids" "local" {
  vpc_id = "${var.vpc_id}"

  tags {
    "airbus:network" = "local"
  }
}
variable "availability_zones" {
  type    = "list"
  default = ["eu-west-1a", "eu-west-1b"]
}

variable "instance_type" {}

variable "launch_ami" {
  default = "ami-84e4e8fd"
}

variable "asg_max" {}
variable "asg_min" {}
variable "asg_capacity" {}
variable "asg_grace" {}
variable "db_engine" {}
variable "db_user" {}
variable "db_instance_class" {}
variable "db_password" {}
