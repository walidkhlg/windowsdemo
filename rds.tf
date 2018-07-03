provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

############# RDS ##############
resource "aws_db_instance" "mssql" {
  identifier             = "demodb"
  vpc_security_group_ids = ["${aws_security_group.rds-sg.id}"]
  engine                 = "${var.db_engine}"

  #multi_az                = true
  instance_class          = "${var.db_instance_class}"
  allocated_storage       = 20
  db_subnet_group_name    = "${aws_db_subnet_group.rds_sub_group.name}"
  username                = "${var.db_user}"
  password                = "${var.db_password}"
  port                    = "1433"
  kms_key_id              = "${var.kms_key}"
  backup_retention_period = 1
  storage_encrypted       = true
  skip_final_snapshot     = true
  license_model           = "license-included"
}

resource "aws_db_subnet_group" "rds_sub_group" {
  name       = "main"
  subnet_ids = ["${data.aws_subnet_ids.local.ids}"]

  tags {
    Name = "DB subnet group"
  }
}

################ elb #############

resource "aws_elb" "web-elb" {
  name            = "web-elb"
  internal        = true
  subnets         = ["${data.aws_subnet_ids.private.ids}"]
  security_groups = ["${aws_security_group.sg-elb.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = "2"
    interval            = "60"
    target              = "TCP:80"
    timeout             = "3"
    unhealthy_threshold = "2"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "web-elb-windows"
  }
}

output "elb-address" {
  value = "${aws_elb.web-elb.dns_name}"
}
