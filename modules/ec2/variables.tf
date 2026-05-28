variable "environment" {
  type        = string
  description = "Назва середовища"
}

variable "vpc_id" {
  type        = string
  description = "ID VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Список публічних підмереж для ALB"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Список приватних підмереж для EC2 інстансів (ASG)"
}

variable "ami_id" {
  type        = string
  description = "ID вашого створеного AMI"
}