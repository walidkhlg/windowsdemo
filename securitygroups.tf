####### Security Groups ####################

resource "aws_security_group" "sg-elb" {
  name   = "allow_web"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "sg-elb-web"
  }
}

resource "aws_security_group" "sg-private" {
  name   = "sg_private-web"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port       = 80
    protocol        = "TCP"
    to_port         = 80
    security_groups = ["${aws_security_group.sg-elb.id}"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "sg_private-web"
  }
}

resource "aws_security_group" "rds-sg" {
  name   = "rds-sg-web"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port       = 1433
    protocol        = "tcp"
    to_port         = 1433
    security_groups = ["${aws_security_group.sg-private.id}"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "rds-sg-web"
  }
}
