variable "name" {
  description = "Name prefix for the bastion host and related resources"
  type        = string
}
variable "vpc_id" {
  description = "ID of the VPC where the bastion host will be created"
  type        = string
}
variable "subnet_id" {
  description = "ID of the subnet where the bastion host will be placed"
  type        = string
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 8
}
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
variable "route53_zone_id" {
  description = "ID of the Route53 hosted zone"
  type        = string
}

variable "user_data" {
  description = "Custom user data script to run on instance launch. If not provided, a default script will be used that installs common tools."
  type        = string
  default     = null
}
