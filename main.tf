terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = "~>1.0"
}

provider "aws" {
  region = var.var_region
}

resource "aws_vpc" "vpc_nginx" {
  cidr_block = "192.168.0.0/23"

  tags = {
    Name = "vpc_nginx"
  }
}

resource "aws_internet_gateway" "nginx_ig" {
  vpc_id = aws_vpc.vpc_nginx.id

  tags = {
    Name = "ig_nginx"
  }
}

resource "aws_subnet" "subnet_nginx" {
  vpc_id                  = aws_vpc.vpc_nginx.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = var.var_av_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_nginx"
  }
}
resource "aws_subnet" "subnet2_nginx" {
  vpc_id                  = aws_vpc.vpc_nginx.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = var.var_av_zone2
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_nginx"
  }
}

resource "aws_route_table" "rt_nginx" {
  vpc_id = aws_vpc.vpc_nginx.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nginx_ig.id
  }
  tags = {
    Name = "RT-nginx"
  }
}

resource "aws_route_table_association" "assrt_nginx" {
  subnet_id      = aws_subnet.subnet_nginx.id
  route_table_id = aws_route_table.rt_nginx.id
}

resource "aws_security_group" "allow_nginx" {
  name   = "allow_nginx"
  vpc_id = aws_vpc.vpc_nginx.id

  ingress {
    description = "allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-NGINX"
  }
}

data "aws_ami" "latest_amzn2_ami" {
  most_recent = true
  name_regex  = "amzn2-ami-kernel-5.10-hvm-2.0.*-x86_64-gp2"
  owners      = ["amazon"]
}

resource "aws_instance" "nginx" {
  ami             = data.aws_ami.latest_amzn2_ami.id
  instance_type   = var.var_instance_type
  subnet_id       = aws_subnet.subnet_nginx.id
  security_groups = [aws_security_group.allow_nginx.id]
  user_data       = file("install_nginx.sh")
  depends_on      = [aws_db_instance.database]
  tags = {
    Name = "Instance_Nginx"
  }
}

resource "aws_db_instance" "database" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = var.var_engine_v
  instance_class         = var.var_db_inst_class
  identifier             = "rdsinstance"
  db_name                = "mydb"
  username               = "sqluser"
  password               = data.aws_ssm_parameter.my_db_password.value
  parameter_group_name   = "default.mysql8.0"
  availability_zone      = var.var_av_zone
  skip_final_snapshot    = true
  publicly_accessible    = false
  db_subnet_group_name  = aws_db_subnet_group.rds_subnetgroup.id
  vpc_security_group_ids = [aws_security_group.allow_mysql.id]
}

resource "aws_security_group" "allow_mysql" {
  name   = "allow_mysql"
  vpc_id = aws_vpc.vpc_nginx.id

  ingress {
    description = "allow MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["192.168.0.0/23"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-MySQL"
  }
}

resource "aws_db_subnet_group" "rds_subnetgroup" {
  name       = "main"
  subnet_ids = [aws_subnet.subnet_nginx.id, aws_subnet.subnet2_nginx.id]

  tags = {
    Name = "My DB subnet group"
  }
}

data "aws_ssm_parameter" "my_db_password" {
  name = "db_password"
}