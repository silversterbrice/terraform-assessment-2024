##########################
### Module Declaratoin ###
##########################


### Networking Resources ###
module "networking" {
  source           = "./networking"
  vpc_cidr         = var.cidr
  max_subnets      = var.max_subnets
  private_sn_count = var.private_sn_counts #2
  public_sn_count  = var.public_sn_counts  #2
  private_cidrs    = [for i in range(1, 255, 2) : cidrsubnet("${var.cidr}", 8, i)]
  public_cidrs     = [for i in range(2, 255, 2) : cidrsubnet("${var.cidr}", 8, i)]
  cidr_open        = var.cidr_open
  security_groups  = local.security_groups

}



### Load balancer resources ###
module "loadbalancing" {
  source = "./loadbalancing"

  vpc_id = module.networking.vpc_id

  aws_lb = {
    name               = var.aws_lb.name
    idle_timeout       = var.aws_lb.idle_timeout
    internal           = var.aws_lb.internal
    load_balancer_type = var.aws_lb.load_balancer_type
    subnets            = module.networking.public_subnets
    security_groups    = module.networking.public_sg
  }

  lb_target_group = {
    port                = var.alb_target.port
    protocol            = var.alb_target.protocol
    healthy_threshold   = var.alb_target.healthy_threshold
    unhealthy_threshold = var.alb_target.unhealthy_threshold
    timeout             = var.alb_target.timeout
    interval            = var.alb_target.interval
  }

  lb_listener = {
    port        = var.alb_listener.port
    protocol    = var.alb_listener.protocol
    status_code = var.alb_listener.status_code
  }

  lb_listener_https = {
    port       = var.lb_listener_https.port
    protocol   = var.lb_listener_https.protocol
    ssl_policy = var.lb_listener_https.ssl_policy
  }

  acm = {
    domain_name       = var.acm.domain_name
    validation_method = var.acm.validation_method
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
    name                = var.nginx_autoscaling.name
    vpc_zone_identifier = [module.networking.public_subnets[0], module.networking.public_subnets[1]] // Assign two public subnets
    desired_capacity    = var.nginx_autoscaling.desired_capacity
    max_size            = var.nginx_autoscaling.max_size
    min_size            = var.nginx_autoscaling.min_size
    target_group_arns   = module.loadbalancing.target_group_arn
    health_check_type   = var.nginx_autoscaling.health_check_type
    refresh_strategy    = var.nginx_autoscaling.refresh_strategy
    health_percentage   = var.nginx_autoscaling.health_percentage
  }

  lb_target_group_arn = module.loadbalancing.target_group_arn[0]
}



### Monitoring resources ###
module "monitoring" {
  source = "./monitoring"

  cloudwatch = {
    dashboard_name    = var.cloudwatch.dashboard_name
    dashboard_body    = file("files/dashboard_config.json")
    log_group         = var.cloudwatch.log_group
    retention_in_days = var.cloudwatch.retention_in_days

  }

  # Cloudtrail
  kms_key_s3 = {
    description             = var.kms_key_s3.description #"KMS key for S3 encryption"
    deletion_window_in_days = var.kms_key_s3.deletion_window_in_days
    enable_key_rotation     = var.kms_key_s3.enable_key_rotation
    bucket                  = var.kms_key_s3.bucket        #"gov-cloudtrail-monitoring-2024"
    sse_algorithm           = var.kms_key_s3.sse_algorithm #"aws:kms"
    cloudtrail_name         = var.kms_key_s3.cloudtrail_name
    s3_key_prefix           = var.kms_key_s3.s3_key_prefix
    enable_logging          = var.kms_key_s3.enable_logging
    force_destroy           = var.kms_key_s3.force_destroy
    object_ownership        = var.kms_key_s3.object_ownership
    acl                     = var.kms_key_s3.acl

  }

  template_file_path = "./files/cloudtrail_bucket_policy.json.tpl" // S3 bucket policy for cloudtrail
}



### Security resources ###
module "Security" {
  source = "./security"

  guardduty_enable = true
}