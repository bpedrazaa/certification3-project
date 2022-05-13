locals {
    subnets_db_ids   = data.aws_ssm_parameters_by_path.vpc_subnets_db.values
    instance_ami = "ami-0022f774911c1d690"
    some_subnet_web_id = data.aws_ssm_parameters_by_path.vpc_subnets_web.values[0]
    db_pass = "db1001001."
}

# Security Group for the DB
resource "aws_security_group" "factory_db_sg" {
  name        = "factory_db_sg"
  vpc_id      = data.aws_ssm_parameter.vpc_id_parameter.value

  ingress {
    description      = "sql-traffic"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "factory_db_sg"
  }
}

# Subnet Group
resource "aws_db_subnet_group" "factory_subnet_group" {
  name       = "factory_subnet_group"
  subnet_ids = local.subnets_db_ids

  tags = {
    Name = "factory_subnet_group"
  }
}

# Database
resource "aws_db_instance" "factory_db" {
  identifier           = "factory-db"
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0.28"
  instance_class       = "db.t3.micro"
  db_name              = "factory_database"
  username             = "admin"
  password             = local.db_pass
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.factory_subnet_group.name
  vpc_security_group_ids = [aws_security_group.factory_db_sg.id]
  
}


# Creation of parameters of the DB

resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/db/endpoint"
  type  = "String"
  value = aws_db_instance.factory_db.address
}
resource "aws_ssm_parameter" "db_username" {
  name  = "/db/username"
  type  = "String"
  value = aws_db_instance.factory_db.username
}
resource "aws_ssm_parameter" "db_name" {
  name  = "/db/db_name"
  type  = "String"
  value = aws_db_instance.factory_db.db_name
}



# Creation of security group for instance to access DB
resource "aws_security_group" "db_instance_access_sg" { 
  name        = "db_instance_access_sg"
  vpc_id      = data.aws_ssm_parameter.vpc_id_parameter.value

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "db_instance_access_sg"
  }
}

# Creation of instance to access DB
resource "aws_instance" "db_instance_access" {
  ami           = local.instance_ami
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.db_instance_access_sg.id]
  subnet_id = local.some_subnet_web_id
  tags = {
    Name = "db-instance-access"
  }
}