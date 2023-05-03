# Cria a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
   enable_dns_hostnames = true
  tags = {
    Name = "my-vpc"
  }
}

# Cria as sub-redes públicas
resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/27"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.32/27"
  availability_zone = "us-east-1b"
  tags = {
    Name = "public-subnet-2"
  }
}

# Cria as sub-redes privadas
resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.12.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-2"
  }
}

# Criar public-route-table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "Public-Route-Table"
  }
}

# Criar private-route-table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "Private-Route-Table"
  }
}

# Fazer as associações de public-route-table
resource "aws_route_table_association" "public-route-1-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public_subnet_1.id
}

resource "aws_route_table_association" "public-route-2-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public_subnet_2.id
}

# Fazer as associações de private-route-table
resource "aws_route_table_association" "private-route-1-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private_subnet_1.id
}

resource "aws_route_table_association" "private-route-2-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private_subnet_2.id
}

# Criar elastic-ip
resource "aws_eip" "elastic-ip-for-nat-gw" {
  vpc                       = true
  associate_with_private_ip = "10.0.0.5"

  tags = {
    Name = "Production-EIP"
  }

  depends_on = [aws_internet_gateway.production-igw]
}

# Criar NAT
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.elastic-ip-for-nat-gw.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = "Production-NAT-GW"
  }

  depends_on = [aws_eip.elastic-ip-for-nat-gw]
}

# Associar Nat a route_table

resource "aws_route" "nat-gw-route" {
  route_table_id         = aws_route_table.private-route-table.id
  nat_gateway_id         = aws_nat_gateway.nat-gw.id
  destination_cidr_block = "0.0.0.0/0"
}

# Criar gateway
resource "aws_internet_gateway" "production-igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "Production-IGW"
  }
}

# Associar gateway a route_table

resource "aws_route" "public-internet-igw-route" {
  route_table_id         = aws_route_table.public-route-table.id
  gateway_id             = aws_internet_gateway.production-igw.id
  destination_cidr_block = "0.0.0.0/0"
}