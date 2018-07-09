############# launch config ######
data "template_file" "userdata" {
  template = "${file("./files/userdata.ps1")}"

  vars {
    bucket_name = "${var.bucket_name}"
    dbhost      = "${aws_db_instance.mssql.endpoint}"
    dbuser      = "${var.db_user}"
    dbpass      = "${var.db_password}"
  }
}

################### Autoscaling Group###############
resource "aws_launch_configuration" "web-lc" {
  name_prefix          = "web-lc-"
  image_id             = "${var.launch_ami}"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${aws_security_group.sg-private.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.web_s3_profile.id}"
  user_data            = "${data.template_file.userdata.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web-asg" {
  max_size                  = "${var.asg_max}"
  min_size                  = "${var.asg_min}"
  desired_capacity          = "${var.asg_capacity}"
  health_check_grace_period = "${var.asg_grace}"
  health_check_type         = "ELB"
  force_delete              = true
  load_balancers            = ["${aws_elb.web-elb.id}"]
  vpc_zone_identifier       = ["${data.aws_subnet_ids.private.ids}"]
  launch_configuration      = "${aws_launch_configuration.web-lc.name}"

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "asg-C2E2-dev-app"
  }
  tag {
    key                 = "airbus:environment"
    propagate_at_launch = true
    value               = "C2E2"
  }
  tag {
    key                 = "airbus:stage"
    propagate_at_launch = true
    value               = "dev"
  }
  tag {
    key                 = "airbus:environment"
    propagate_at_launch = true
    value               = "dev"
  }
}

##################### scale policy ##############
resource "aws_autoscaling_policy" "cpu-policy" {
  name                   = "cpu-policy"
  autoscaling_group_name = "${aws_autoscaling_group.web-asg.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm" {
  alarm_name          = "cpu-alarm"
  alarm_description   = "cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.web-asg.name}"
  }

  alarm_actions = ["${aws_autoscaling_policy.cpu-policy.arn}"]
}

# scale down alarm
resource "aws_autoscaling_policy" "cpu-policy-scaledown" {
  name                   = "cpu-policy-scaledown"
  autoscaling_group_name = "${aws_autoscaling_group.web-asg.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm-scaledown" {
  alarm_name          = "cpu-alarm-scaledown"
  alarm_description   = "cpu-alarm-scaledown"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.web-asg.name}"
  }

  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.cpu-policy-scaledown.arn}"]
}

######## instance profile ########################

resource "aws_iam_instance_profile" "web_s3_profile" {
  name = "web_s3_profile"
  role = "${var.instance_role}"
}
