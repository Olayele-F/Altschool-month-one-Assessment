terraform {
    required_version = ">= 1.14.7"
    required_providers {
         aws = {
      source  = "hashicorp/aws"
      version = "6.40.0"
       }
    }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
 #creating the vpc

resource "aws_vpc" "techcorp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "techcorp-vpc"
  }
}
 #creating the public subnets

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # Essential for the Bastion Host

  tags = {
    Name = "techcorp-public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.techcorp_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "techcorp-public-subnet-2"
  }
}

# Private Subnets

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "techcorp-private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.techcorp_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "techcorp-private-subnet-2"
  }
}

#creating the Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.techcorp_vpc.id

  tags = {
    Name = "techcorp-igw"
  }
}

# Public Route Table

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "techcorp-public-rt"
  }
}

# Association of Public Subnets with the Public Route Table

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

# a Private Route Table (No IGW access)

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.techcorp_vpc.id

  tags = {
    Name = "techcorp-private-rt"
  }
}

#Association of Private Subnets with the Private Route Table

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}

#Bastion Security Group

resource "aws_security_group" "bastion_sg" {
  name        = "techcorp-bastion-sg"
  description = "Allow SSH from my current IP"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description = "SSH from developer"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Adds /32 to  IP to make it a specific CIDR block
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-bastion-sg" }
}

#Web Security Group

resource "aws_security_group" "web_sg" {
  name        = "techcorp-web-sg"
  description = "Allow HTTP/HTTPS from anywhere and SSH from Bastion"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # Source is the Bastion SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-web-sg" }
}

#Database Security Group

resource "aws_security_group" "db_sg" {
  name        = "techcorp-db-sg"
  description = "Allow Postgres from Web SG and SSH from Bastion"
  vpc_id      = aws_vpc.techcorp_vpc.id

  ingress {
    description     = "PostgreSQL from Web"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "techcorp-db-sg" }
}

# Bastion Host

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.bastion_instance_type
  subnet_id     = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  # Enable Password Auth via User Data

  user_data = <<-EOF
              #!/bin/bash
              echo "ec2-user:Olayele66" | chpasswd
              sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
              systemctl restart sshd
              EOF

  tags = { Name = "techcorp-bastion" }
}

# Elastic IP for Bastion

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  tags     = { Name = "techcorp-bastion-eip" }
}

# webservers

resource "aws_instance" "web_server" {
  count         = 2
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.web_instance_type
  user_data = file("user_data/web_server_setup.sh")

  # Logic to alternate subnets: 0 goes to private_1, 1 goes to private_2

  subnet_id              = count.index == 0 ? aws_subnet.private_1.id : aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

    tags = { Name = "techcorp-web-${count.index + 1}" }
}

#Database Server

resource "aws_instance" "db_server" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.db_instance_type
  subnet_id     = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  user_data = file("user_data/db_server_setup.sh")

    tags = { Name = "techcorp-db-server" }
}

#Elastic IP for the NAT Gateway

resource "aws_eip" "nat_eip" {
  tags = { Name = "techcorp-nat-eip" }
}

# the NAT Gateway in the first Public Subnet

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id # Must be in a public subnet

  tags = { Name = "techcorp-nat-gateway" }

   depends_on = [aws_internet_gateway.igw]
}

#Update the Private Route Table
# We add a route that points all internet traffic (0.0.0.0/0) to the NAT Gateway

resource "aws_route" "private_nat_route"{
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# 1. Application Load Balancer
resource "aws_lb" "techcorp_alb" {
  name               = "techcorp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "techcorp-alb" }
}

# 2. Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "techcorp-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.techcorp_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# 3. Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.techcorp_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# 4. Target Group Attachment (Registering the Web Servers)
resource "aws_lb_target_group_attachment" "web_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server[count.index].id
  port             = 80
}

