# --- Compute/main.tf ---


### Key Pair for EC2 ###
resource "aws_key_pair" "gov_auth" {
  key_name   = var.key_name
 # public_key = file(var.public_key_path)
 public_key = var.public_key_path
}



### Launch template ###
resource "aws_launch_template" "nginx_lt" {
  name = var.launch_template.name

  description   = "Launch template for nginx instances"
  ebs_optimized = true

  update_default_version = true

  block_device_mappings {
    device_name = var.launch_template.device_name 

    ebs {
      volume_size = var.launch_template.volume_size
      encrypted   = false
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  key_name               = aws_key_pair.gov_auth.id
  vpc_security_group_ids = [var.launch_template.vpc_security_group_ids]

  image_id      = var.launch_template.image_id
  instance_type = var.launch_template.instance_type

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install nginx -y
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "gov_nginx_LT"
  }
}



### Autoscaling Group for Nginx ###
resource "aws_autoscaling_group" "nginx_asg" {
  name                =  var.autoscaling.name
  vpc_zone_identifier =  var.autoscaling.vpc_zone_identifier   
  desired_capacity    =  var.autoscaling.desired_capacity 
  max_size            =  var.autoscaling.max_size
  min_size            =  var.autoscaling.min_size
  target_group_arns   =  var.autoscaling.target_group_arns  
  health_check_type   =  var.autoscaling.health_check_type

  launch_template {
    id      = aws_launch_template.nginx_lt.id
    version = "$Latest"
  }

  instance_refresh {
    strategy                    = var.autoscaling.refresh_strategy  
    preferences {
    
      min_healthy_percentage    = var.autoscaling.health_percentage           
    }
    triggers = [ "desired_capacity" ] 
  }
 
   tag {
    key                 = "Name"
    value               =  var.autoscaling.name  
    propagate_at_launch = true
   }
}



### ALB Target Group attachment ###
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.nginx_asg.id
  lb_target_group_arn    = var.lb_target_group_arn
}