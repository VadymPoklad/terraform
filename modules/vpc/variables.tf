variable "vpc_cidr" {
  type = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "environment" {
  type = string
  description = "Environment name used as a prefix for resources"
  default     = "jira-clone"
}

variable "azs" {
  type = list(string)
  description = "List of availability zones"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets_cidr" {
  type = list(string)
  description = "List of CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  type = list(string)
  description = "List of CIDR blocks for private subnets"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "database_subnets_cidr" {
  type = list(string)
  description = "List of CIDR blocks for database subnets"
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}