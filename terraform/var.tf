variable "target_env" {
  description = "AWS workload account env (e.g. dev, test, prod, sandbox, unclass)"
}

variable "target_aws_account_id" {
  description = "AWS workload account id"
}

variable "git_url" {
  description = "url of the git repo to clone"
  default     = "github.com/rloisell/startup-sample-project-aws-virtual-machines.git"
  type        = string
}

variable "sha" {
  description = "Id of the git commit to checkout"
  type        = string
}
variable "lc_name" {
  description = "Name of the launch configuration"
  default     = "sssp-vm-lc"
  type        = string
}
# A single line comment. 
variable "iamge_id" {
  description = "id of the ami used"
  default     = "ami-06e39367bd3bb5000"
  type        = string
}

variable "asg_name" {
  description = "name of the autoscaling group created"
  default     = "ssp-vm-asg"
  type        = string
}
variable "branch" {
  description = "name of the autoscaling group created"
  default     = "main"
  type        = string
}

variable "table_name" {
  description = "name of the dynamodb table created"
  default     = "ssp-greetings-vm"
  type        = string
}
variable "instances_name" {
  description = "name of the asg instances created"
  default     = "asg-instances"
  type        = string
}

variable "policy_name" {
  description = "name of the policy created"
  default     = "ssp_db"
  type        = string
}
variable "role_name" {
  description = "name of the role created"
  default     = "ssp-db"
  type        = string
}
variable "iam_profile" {
  description = "name of the IAM profile created"
  default     = "ssp_profile"
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
  default     = ["vm-app", "vm-startup-sample-app"]
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
