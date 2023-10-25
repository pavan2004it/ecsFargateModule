resource "aws_ecs_cluster" "rp-ecs-cluster" {
  name = var.cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "rp-task-definitions" {
  for_each = var.task_definitions
  container_definitions = jsonencode(each.value.containerDefinitions)
  family = each.value.family
  cpu = each.value.cpu
  memory = each.value.memory
  task_role_arn = each.value.task_role_arn
  execution_role_arn = each.value.execution_role_arn
  network_mode = each.value.network_mode
}

resource "aws_ecs_task_definition" "rp-task-definitions-wp" {
  for_each = var.task_definitions_wp
  container_definitions = jsonencode(each.value.containerDefinitions)
  family = each.value.family
  dynamic "volume" {
    for_each = var.task_definitions_wp.volume
    content {
      name = each.value.volume.name
      efs_volume_configuration {
        file_system_id = each.value.volume.efs_volume_configuration.file_system_id
        root_directory = each.value.volume.efs_volume_configuration.root_directory
      }
    }
  }
  cpu = each.value.cpu
  memory = each.value.memory
  task_role_arn = each.value.task_role_arn
  execution_role_arn = each.value.execution_role_arn
  network_mode = each.value.network_mode
}


resource "aws_ecs_service" "rp-services-sn" {
  for_each = var.services
  name              = each.value.name
  cluster = aws_ecs_cluster.rp-ecs-cluster.name
  task_definition   = each.value.task_definition
  desired_count     = each.value.desired_count
  launch_type       = each.value.launch_type
  enable_execute_command = true
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  dynamic "load_balancer" {
    for_each = each.value.load_balancer != null ? [each.value.load_balancer] : []
    content {
      container_name  = each.value.load_balancer.container_name
      container_port  = each.value.load_balancer.container_port
      target_group_arn = each.value.load_balancer.target_group_arn
    }
  }
  network_configuration {
    subnets = each.value.network_configuration.subnets
    security_groups = var.private-sg
    assign_public_ip = each.value.network_configuration.assign_public_ip
  }
  tags = each.value.tags
}

resource "aws_ecs_service" "rp-services-wsn" {
  for_each = var.services_wsn
  name              = each.value.name
  cluster = aws_ecs_cluster.rp-ecs-cluster.name
  task_definition   = each.value.task_definition
  desired_count     = each.value.desired_count
  launch_type       = each.value.launch_type
  enable_execute_command = true
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  network_configuration {
    subnets = each.value.network_configuration.subnets
    security_groups = var.private-sg
    assign_public_ip = each.value.network_configuration.assign_public_ip
  }
  tags = each.value.tags
}

### Autoscaling Config for Services with Alb

resource "aws_appautoscaling_target" "ecs_target_walb" {
  for_each = var.services
  max_capacity       = 5
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.rp-ecs-cluster.name}/${each.value.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_scaling_policy_walb" {
  for_each = var.services
  name               = "cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target_walb[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target_walb[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target_walb[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}

resource "aws_appautoscaling_policy" "memory_scaling_policy_walb" {
  for_each = var.services
  name               = "memory-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target_walb[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target_walb[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target_walb[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 70
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm_walb" {
  for_each             = var.services
  alarm_name          = "cpu-alarm-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "CPUUtilization exceeds 70% for 1 minute"
  alarm_actions       = [aws_appautoscaling_policy.cpu_scaling_policy_walb[each.key].arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.rp-ecs-cluster.name
    ServiceName = each.value.name
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm_walb" {
  for_each             = var.services
  alarm_name          = "memory-alarm-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "MemoryUtilization exceeds 70% for 1 minute"
  alarm_actions       = [aws_appautoscaling_policy.memory_scaling_policy_walb[each.key].arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.rp-ecs-cluster.name
    ServiceName = each.value.name
  }
}


### Autoscaling Config for Services without Alb

resource "aws_appautoscaling_target" "ecs_target" {
  for_each = var.services_wsn
  max_capacity       = 5
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.rp-ecs-cluster.name}/${each.value.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_scaling_policy" {
  for_each = var.services_wsn
  name               = "cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}

resource "aws_appautoscaling_policy" "memory_scaling_policy" {
  for_each = var.services_wsn
  name               = "memory-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 70
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  for_each             = var.services_wsn
  alarm_name          = "cpu-alarm-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "CPUUtilization exceeds 70% for 1 minute"
  alarm_actions       = [aws_appautoscaling_policy.cpu_scaling_policy[each.key].arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.rp-ecs-cluster.name
    ServiceName = each.value.name
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  for_each             = var.services_wsn
  alarm_name          = "memory-alarm-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "MemoryUtilization exceeds 70% for 1 minute"
  alarm_actions       = [aws_appautoscaling_policy.memory_scaling_policy[each.key].arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.rp-ecs-cluster.name
    ServiceName = each.value.name
  }
}





