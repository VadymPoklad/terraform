output "vpc_id" {
  description = "ID створеної VPC"
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Список ID публічних підмереж"
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Список ID приватних підмереж"
  value = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Список ID підмереж бази даних"
  value = aws_subnet.database[*].id
}

output "db_subnet_group_name" {
  description = "Ім'я групи підмереж бази даних"
  value = aws_db_subnet_group.this.name
}