variable "var_region" {
  type    = string
  default = "eu-west-1"
}

variable "var_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "var_av_zone" {
  type    = string
  default = "eu-west-1a"
}

variable "var_av_zone2" {
  type    = string
  default = "eu-west-1b"
}

variable "var_engine_v" {
  type    = string
  default = "8.0.27"
}

variable "var_db_inst_class" {
  type    = string
  default = "db.t2.micro"
}