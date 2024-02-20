# --- Loadbalancing/outputs.tf ---


output "target_group_arn" {
  value = aws_lb_target_group.gov_tg.*.arn
}