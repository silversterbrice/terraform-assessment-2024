# --- loadbalancing/main.tf ---


### ALB Resource ###
resource "aws_lb" "gov_lb" {
  name               = var.aws_lb.name
  subnets            = var.aws_lb.subnets
  security_groups    = [var.aws_lb.security_groups]
  idle_timeout       = var.aws_lb.idle_timeout
  internal           = var.aws_lb.internal
  load_balancer_type = var.aws_lb.load_balancer_type
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


### ALB Listener - HTTP Redirect ####
resource "aws_lb_listener" "gov_lb_listener" {
  load_balancer_arn = aws_lb.gov_lb.arn
  port              = var.lb_listener.port
  protocol          = var.lb_listener.protocol
  default_action {
    type             = "redirect"
    target_group_arn = aws_lb_target_group.gov_tg.arn

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = var.lb_listener.status_code // "HTTP_301"
    }
  }
}

### ALB Listener - HTTPS ####
resource "aws_lb_listener" "gov_lb_listener_https" {
  load_balancer_arn = aws_lb.gov_lb.arn
  port              = var.lb_listener_https.port     // 443
  protocol          = var.lb_listener_https.protocol // "HTTPS"
  ssl_policy        = var.lb_listener_https.ssl_policy
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gov_tg.arn
  }
}

###  Certificate ###
resource "aws_acm_certificate" "cert" {
  domain_name       = var.acm.domain_name
  validation_method = var.acm.validation_method //"DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = aws_acm_certificate.cert.domain_validation_options[*].resource_record_name
}
