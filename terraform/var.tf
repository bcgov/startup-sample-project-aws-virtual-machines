variable "target_env" {
  description = "AWS workload account env (e.g. dev, test, prod, sandbox, unclass)"
}

variable "target_aws_account_id" {
  description = "AWS workload account id"
}

variable "alb_name" {
  description = "Name of the internal alb"
  default     = "default"
  type        = string
}
variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 8080
}
variable "health_check_path" {
  default = "/"
}
variable "service_names" {
  description = "List of service names to use as subdomains"
  default     = ["ssp-vm", "startup-app-vm"]
  type        = list(string)
}

variable "common_tags" {
  description = "Common tags for created resources"
  default = {
    Application = "Startup Sample"
  }
}

variable "aws_region" {
  description = "region of the aws"
  default     = "ca-central-1"
  type        = string
}
