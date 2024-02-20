


cidr = "192.168.0.0/16"

private_sn_counts = 2
public_sn_counts  = 2
max_subnets       = 10
cidr_open         = "0.0.0.0/0"
access_ip         = "0.0.0.0/0"


alb_target = {
  port                = 80
  protocol            = "HTTP"
  healthy_threshold   = 2
  unhealthy_threshold = 2
  timeout             = 3
  interval            = 30
}


alb_listener = {
  port     = 80
  protocol = "HTTP"
}


nginx_launch_template = {
  name          = "gov-nginx-Launch-template"
  device_name   = "/dev/sda1"
  volume_size   = 30
  volume_type   = "gp2"
  image_id      = "ami-0fa377108253bf620"
  instance_type = "t2.micro"

}


nginx_autoscaling = {
    name                =  "gov-nginx-asg"
    desired_capacity    =  2
    max_size            =  3
    min_size            =  2
    health_check_type   =  "ELB"
    refresh_strategy    =  "Rolling"
    health_percentage   =  90
}


public_key_path = "c:\\users\\Monica\\.ssh\\govkey.pub"
key_name        = "govkey"