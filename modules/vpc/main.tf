resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# ------------------------------------------------------------------------------
# ПІДМЕРЕЖІ
# ------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidr)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets_cidr[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true # Автоматично видавати публічний IP інстансам

  tags = {
    Name = "${var.environment}-public-${var.azs[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets_cidr[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.environment}-private-${var.azs[count.index]}"
  }
}

resource "aws_subnet" "database" {
  count             = length(var.database_subnets_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.database_subnets_cidr[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.environment}-db-${var.azs[count.index]}"
  }
}

# ------------------------------------------------------------------------------
# ШЛЮЗИ
# ------------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_eip" "nat" {
  count  = length(var.public_subnets_cidr)
  domain = "vpc"
  tags = {
    Name = "${var.environment}-nat-eip-${var.azs[count.index]}"
  }
}

resource "aws_nat_gateway" "this" {
  count         = length(var.public_subnets_cidr)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.environment}-nat-${var.azs[count.index]}"
  }
  depends_on = [aws_internet_gateway.this]
}

# ------------------------------------------------------------------------------
# ТАБЛИЦІ МАРШРУТИЗАЦІЇ ТА АСОЦІАЦІЇ
# ------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.environment}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets_cidr)
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }
  tags = { Name = "${var.environment}-private-rt-${var.azs[count.index]}" }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.this.id
  # У БД немає маршруту ні в IGW, ні в NAT. Повна ізоляція.
  tags = { Name = "${var.environment}-db-rt" }
}

resource "aws_route_table_association" "database" {
  count          = length(var.database_subnets_cidr)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# ------------------------------------------------------------------------------
# RDS SUBNET GROUP (Групуємо DB підмережі для бази даних)
# ------------------------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}