# Outputs for Monitoring Module

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.application_dashboard.dashboard_name}"
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.application_dashboard.dashboard_name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.application_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.application_logs.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.name
}

output "alarm_names" {
  description = "List of all CloudWatch alarm names"
  value = [
    aws_cloudwatch_metric_alarm.frontend_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.backend_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.frontend_high_memory.alarm_name,
    aws_cloudwatch_metric_alarm.backend_high_memory.alarm_name,
    aws_cloudwatch_metric_alarm.database_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.database_high_connections.alarm_name,
    aws_cloudwatch_metric_alarm.alb_high_response_time.alarm_name,
    aws_cloudwatch_metric_alarm.alb_high_5xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.application_errors.alarm_name
  ]
}

output "monitoring_summary" {
  description = "Summary of monitoring resources created"
  value = {
    dashboard_name     = aws_cloudwatch_dashboard.application_dashboard.dashboard_name
    dashboard_url      = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.application_dashboard.dashboard_name}"
    log_group         = aws_cloudwatch_log_group.application_logs.name
    alerts_topic      = aws_sns_topic.alerts.name
    alarm_count       = 9
    log_retention     = var.log_retention_days
    alert_email       = var.alert_email != "" ? var.alert_email : "Not configured"
  }
}