variable "vpc_cidr" {
  type = string
  description = "CIDR блок для VPC"
  default     = "10.0.0.0/16"
}

variable "environment" {
  type = string
  description = "Назва середовища, що використовується як префікс для ресурсів"
  default     = "jira-clone"
}

variable "azs" {
  type = list(string)
  description = "Список зон доступності"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets_cidr" {
  type = list(string)
  description = "Список CIDR блоків для публічних підмереж"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  type = list(string)
  description = "Список CIDR блоків для приватних підмереж"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "database_subnets_cidr" {
  type = list(string)
  description = "Список CIDR блоків для підмереж бази даних"
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}