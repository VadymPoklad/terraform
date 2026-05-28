variable "environment" {
  type        = string
  description = "Назва середовища"
}

variable "vpc_id" {
  type        = string
  description = "ID VPC для розгортання Security Group"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR VPC для налаштування доступу до бази даних"
}

variable "db_subnet_group_name" {
  type        = string
  description = "Ім'я групи підмереж для RDS"
}