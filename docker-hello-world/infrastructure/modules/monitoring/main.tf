# CloudWatch Monitoring Module
# Comprehensive monitoring with dashboards, alarms, and insights

# CloudWatch Log Groups for application logging
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/ecs/${var.cluster_name}-app"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.environment}-application-logs"
    Environment = var.environment
    Service     = "ECS"
  }
}

# CloudWatch Dashboard for Application Monitoring
resource "aws_cloudwatch_dashboard" "application_dashboard" {
  dashboard_name = "${var.environment}-guestbook-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.frontend_service_name, "ClusterName", var.cluster_name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.backend_service_name, "ClusterName", var.cluster_name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service Performance"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.load_balancer_arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Load Balancer Metrics"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.database_identifier],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeableMemory", ".", "."],
            [".", "ReadLatency", ".", "."],
            [".", "WriteLatency", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Database Performance"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 18
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.application_logs.name}' | fields @timestamp, @message | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Recent Application Logs"
          view    = "table"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-dashboard"
    Environment = var.environment
  }
}

# CloudWatch Alarms for High CPU Usage
resource "aws_cloudwatch_metric_alarm" "frontend_high_cpu" {
  alarm_name          = "${var.environment}-frontend-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS frontend CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.frontend_service_name
  }

  tags = {
    Name        = "${var.environment}-frontend-cpu-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_high_cpu" {
  alarm_name          = "${var.environment}-backend-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS backend CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.backend_service_name
  }

  tags = {
    Name        = "${var.environment}-backend-cpu-alarm"
    Environment = var.environment
  }
}

# CloudWatch Alarms for High Memory Usage
resource "aws_cloudwatch_metric_alarm" "frontend_high_memory" {
  alarm_name          = "${var.environment}-frontend-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors ECS frontend memory utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.frontend_service_name
  }

  tags = {
    Name        = "${var.environment}-frontend-memory-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_high_memory" {
  alarm_name          = "${var.environment}-backend-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors ECS backend memory utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.backend_service_name
  }

  tags = {
    Name        = "${var.environment}-backend-memory-alarm"
    Environment = var.environment
  }
}

# Database Performance Alarms
resource "aws_cloudwatch_metric_alarm" "database_high_cpu" {
  alarm_name          = "${var.environment}-database-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.database_identifier
  }

  tags = {
    Name        = "${var.environment}-database-cpu-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "database_high_connections" {
  alarm_name          = "${var.environment}-database-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "This metric monitors RDS connection count"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.database_identifier
  }

  tags = {
    Name        = "${var.environment}-database-connections-alarm"
    Environment = var.environment
  }
}

# Load Balancer Health Alarms
resource "aws_cloudwatch_metric_alarm" "alb_high_response_time" {
  alarm_name          = "${var.environment}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "This metric monitors ALB response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
  }

  tags = {
    Name        = "${var.environment}-alb-response-time-alarm"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_high_5xx_errors" {
  alarm_name          = "${var.environment}-alb-high-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors ALB 5XX error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
  }

  tags = {
    Name        = "${var.environment}-alb-5xx-errors-alarm"
    Environment = var.environment
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-guestbook-alerts"

  tags = {
    Name        = "${var.environment}-alerts"
    Environment = var.environment
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "alerts_policy" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "alerts-policy"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarmsToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Email subscription for alerts (optional)
resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Container Insights for ECS Cluster
# Note: Capacity providers are managed by the ECS module to avoid conflicts

# Custom Metric Filters for Application Logs
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.environment}-error-count"
  log_group_name = aws_cloudwatch_log_group.application_logs.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "GuestbookApp/${var.environment}"
    value     = "1"
  }
}

# Alarm for Application Errors
resource "aws_cloudwatch_metric_alarm" "application_errors" {
  alarm_name          = "${var.environment}-application-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "GuestbookApp/${var.environment}"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors application error count"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "${var.environment}-application-errors-alarm"
    Environment = var.environment
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}