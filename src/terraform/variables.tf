variable "app_name" {
  description = "Name of the application"
  default     = "bcparks-dam-vm"
  type        = string
}

variable "target_env" {
  description = "AWS workload account env (e.g. dev, test, prod, sandbox, unclass)"
}

variable "lc_name" {
  description = "Name of the launch configuration"
  default     = "dam-vm-lc"
  type        = string
}

variable "image_id" {
  description = "id of the ami used"
  default     = "ami-03e6e252d463d4bfc"
  type        = string
}

variable "asg_name" {
  description = "name of the autoscaling group created"
  default     = "dam-vm-asg"
  type        = string
}

variable "app_port" {
  description = "Port exposed by the VM image to redirect traffic to"
  default     = 80
}

variable "health_check_path" {
  default = "/login.php"
}

variable "common_tags" {
  description = "Common tags for created resources"
  default = {
    Application = "BCParks DAM"
  }
}

variable "aws_region" {
  description = "region of the aws"
  default     = "ca-central-1"
  type        = string
}

variable "service_names" {
  description = "List of service names to use as subdomains"
  default     = ["dam"]
  type        = list(string)
}

variable "alb_name" {
  description = "Name of the internal alb"
  default     = "default"
  type        = string
}
