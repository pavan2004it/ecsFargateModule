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
    tags = optional(map(string))
  }))
}


variable "task_definitions" {
  type = map(object ({
    containerDefinitions = list(object({
      name        = string
      image       = string
      environment = list(map(string))
      portMappings = optional(any)
      mountPoints = optional(list(object({
        sourceVolume = string
        containerPath = string
      })))
      secrets = list(map(string))
      logConfiguration = any
    }))
    volume = optional(list(object({
      name = string
      efs_volume_configuration = object({
        file_system_id = string
        root_directory = string
      })
    })))
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
      entryPoint = optional(list(string))
      command = optional(list(string))
      mountPoints = optional(list(object({
        sourceVolume = string
        containerPath = string
      })))
      logConfiguration = any
    }))
    volume = optional(list(object({
      name = string
      efs_volume_configuration = object({
        file_system_id = string
        root_directory = string
      })
    })))
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
    tags = optional(map(string))
  }))
}


variable "private_subnets" {
  type = list(string)
  default = []
}

variable "private-sg" {
  type = list(string)

}

variable "cluster_name" {
  type = string
  default = ""
}

variable "vpc-id" {
  type = string
}

variable "rds-sg-id" {
  type = string
}
variable "service_tags" {
  type = map(string)
  default = {}
}

variable "max_capacity_walb" {
  type = number
  default = 1
}

variable "min_capacity_walb" {
  type = number
  default = 1
}

variable "max_capacity_nalb" {
  type = number
  default = 1
}

variable "min_capacity_nalb" {
  type = number
  default = 1
}











