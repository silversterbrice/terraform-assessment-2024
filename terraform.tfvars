


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


#public_key_path = "c:\\terraform-code\\manifest\\govkey.pub"
public_key_path = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDH+d7p7EO5J5vnYOCH6L1G5iOErIl1FStgCjEo4HgzZ53py7rHLgEGItqCdUpk5lkTdHNq19BCw4JZMJFhTheL89jpfbcmny+u+xbFv5u4p6gvpY9vS4KCsRVJwIYFfBAD63/wIPFTpuSQNb0nXgdsbUK2Gb2EUYU7EiWGv8haDlr3fIy9Bb06jJ4KwzC8uklBHa0dKr6Df2AiVqPOFwUcJyENyUTJ+vY+qGafp2BAKOc+eVuZE/eBBnnNZXEUJS8Tt7LoHqB6thHLu+tqsdNiGRmdqFKIbAc8Mo393tMqaiTqqs0nbioyf6TjxmD9LM1BiqFPTnEN17qvmyg8swyZl4NGj35Z1JsDsmMF/T41Iw4VO4ZpzsKTDj64uEkUaa6ZC6i5ndn6WuQHAMaOsFM6z/AE+zsgb3a6VThgd5YBHx/9QJBoqBULS6tIM7/LX9hiou+G5ER/DppW6dp5dhi5XATgeYUpgLye6M39nB//u5pdZZrL0FZM/qtNBBvdu5c= monica@LAPTOP-9O38E7HS"
key_name        = "govkey"


cloudwatch = {
  dashboard_name  =   "gov-nginx-cloudwatch-monitoring"
  log_group       =   "gov-nginx-cloudwatch-log_group"
  retention_in_days = 30
}