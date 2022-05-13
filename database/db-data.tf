data "aws_ssm_parameter" "vpc_id_parameter" { 
  name = "/vpc/id"
}

data "aws_ssm_parameters_by_path" "vpc_subnets_db" {
  path = "/vpc/subnets/db"
}

data "aws_ssm_parameters_by_path" "vpc_subnets_web"{
  path = "/vpc/subnets/web"
}
