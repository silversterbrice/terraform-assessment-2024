# --- loadbalancing/main.tf ---

### ALB Resource ###
resource "aws_lb" "gov_lb" {
  name            = "gov-loadbalancer"
  subnets         = var.public_subnets
  security_groups = [var.public_sg]
  idle_timeout    = 400
}

### ALB Target group ###
resource "aws_lb_target_group" "gov_tg" {
  name     = "gov-lb-tg-${substr(uuid(), 0, 3)}"
  port     = var.lb_target_group.port
  protocol = var.lb_target_group.protocol
  vpc_id   = var.vpc_id
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
  health_check {
    healthy_threshold   = var.lb_target_group.healthy_threshold
    unhealthy_threshold = var.lb_target_group.unhealthy_threshold
    timeout             = var.lb_target_group.timeout
    interval            = var.lb_target_group.interval
  }
}


### ALB Listener ####
resource "aws_lb_listener" "gov_lb_listener" {
  load_balancer_arn = aws_lb.gov_lb.arn
  port              = var.lb_listener.port
  protocol          = var.lb_listener.protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gov_tg.arn
  }
}