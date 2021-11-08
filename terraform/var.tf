variable "target_env" {
  description = "AWS workload account env (e.g. dev, test, prod, sandbox, unclass)"
}

variable "target_aws_account_id" {
  description = "AWS workload account id"
}
variable "git_repo" {
  description = "Name of the git repo to clone"
  default     = "github.com/bcgov/startup-sample-project-aws-virtual-machines.git"
  type        = string
}
variable "BRANCH_NAME" {
  description = "Name of the git branch to clone"
  default     = "main"
  type        = string
}
variable "sha" {
  description = "Id of the git commit to checkout"
  type        = string
}
variable "target_group_name" {
  description = "Name of the target group"
  default     = "sample-target-group-vm"
  type        = string
}
variable "lc_name" {
  description = "Name of the launch configuration"
  default     = "sssp-vm-lc"
  type        = string
}
variable "iamge_id" {
  description = "id of the ami used"
  default     = "ami-037c167242ac48a38"
  type        = string
}

variable "asg_name" {
  description = "name of the autoscaling group created"
  default     = "ssp-vm-asg"
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