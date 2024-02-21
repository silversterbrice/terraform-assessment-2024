

resource "aws_cloudwatch_dashboard" "main" {

  dashboard_name  = var.cloudwatch.dashboard_name
  dashboard_body  = var.cloudwatch.dashboard_body
} 

resource "aws_cloudwatch_log_group" "log_group" {
  
  name                  = var.cloudwatch.log_group
  retention_in_days     = var.cloudwatch.retention_in_days

   
}