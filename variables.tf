variable "services" {
  type = map(object ({
    task_definition = string
    name = string
    desired_count = string
    launch_type = string
    load_balancer = optional(map(any))
    network_configuration = object({
      subnets = list(string)
      security_groups = list(string)
      assign_public_ip = bool
    })
  }))
}


variable "task_definitions" {
  type = map(object ({
    containerDefinitions = list(object({
      name        = string
      image       = string
      environment = list(map(string))
      portMappings = optional(any)
      secrets = list(map(string))
      logConfiguration = any
    }))
    cpu = string
    memory = string
    family = string
    execution_role_arn = string
    task_role_arn = string
    network_mode = string
  }))

}

variable "task_definitions_wp" {
  type = map(object ({
    containerDefinitions = list(object({
      name        = string
      image       = string
      environment = list(map(string))
      secrets = list(map(string))
      logConfiguration = any
    }))
    cpu = string
    memory = string
    family = string
    execution_role_arn = string
    task_role_arn = string
    network_mode = string
  }))

}


variable "services_wsn" {
  type = map(object ({
    task_definition = string
    name = string
    desired_count = string
    launch_type = string
    load_balancer = optional(map(any))
    network_configuration = object({
      subnets = list(string)
      security_groups = list(string)
      assign_public_ip = bool
    })
  }))
}


variable "private_subnets" {
  type = list(string)
  default = []
}

variable "private-sg" {
  type = list(string)

}

variable "alb-sg" {
  type = list(string)
}

variable "cluster_name" {
  type = string
  default = ""
}

variable "vpc-id" {
  type = string
}

variable "alb-sg-id" {
  type = string
}

variable "rds-sg-id" {
  type = string
}






