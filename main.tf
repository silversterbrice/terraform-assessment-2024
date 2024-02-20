### Module Declaratoin ###


### Networking Resources ###
module "networking" {
  source = "./networking"
  vpc_cidr = var.cidr
  max_subnets      = var.max_subnets
  private_sn_count = var.private_sn_counts #2
  public_sn_count  = var.public_sn_counts  #2
  private_cidrs   = [for i in range(1, 255, 2) : cidrsubnet("${var.cidr}", 8, i)]
  public_cidrs    = [for i in range(2, 255, 2) : cidrsubnet("${var.cidr}", 8, i)]
  cidr_open       = var.cidr_open
  security_groups = local.security_groups

}



### Load balancer resources ###
module "loadbalancing" {
  source         = "./loadbalancing"
  public_sg      = module.networking.public_sg
  public_subnets = module.networking.public_subnets
  vpc_id         = module.networking.vpc_id

  lb_target_group = {
    port                = var.alb_target.port
    protocol            = var.alb_target.protocol
    healthy_threshold   = var.alb_target.healthy_threshold
    unhealthy_threshold = var.alb_target.unhealthy_threshold
    timeout             = var.alb_target.timeout
    interval            = var.alb_target.interval
  }

  lb_listener = {
    port     = var.alb_listener.port
    protocol = var.alb_listener.protocol

  }
}



### Compute resources ###
module "compute" {
  source = "./compute"

  public_key_path = var.public_key_path
  key_name        = var.key_name

  launch_template = {
    name                   = var.nginx_launch_template.name
    device_name            = var.nginx_launch_template.device_name
    volume_size            = var.nginx_launch_template.volume_size
    vpc_security_group_ids = module.networking.public_sg
    image_id               = var.nginx_launch_template.image_id
    instance_type          = var.nginx_launch_template.instance_type
  }

  autoscaling = {
    name                =  var.nginx_autoscaling.name
    vpc_zone_identifier =  [ module.networking.public_subnets[0],module.networking.public_subnets[1] ]  
    desired_capacity    =  var.nginx_autoscaling.desired_capacity 
    max_size            =  var.nginx_autoscaling.max_size
    min_size            =  var.nginx_autoscaling.min_size
    target_group_arns   =  module.loadbalancing.target_group_arn
    health_check_type   =  var.nginx_autoscaling.health_check_type
    refresh_strategy    =  var.nginx_autoscaling.refresh_strategy
    health_percentage   =  var.nginx_autoscaling.health_percentage
  }

  lb_target_group_arn   =  module.loadbalancing.target_group_arn[0]
}