variable "aws_region" {
  default = "ap-southeast-1"
}

variable "cidr" {
  type = string
}

variable "private_sn_counts" {
  type = number
}

variable "public_sn_counts" {
  type = number
}

variable "max_subnets" {
  type = number
}

variable "cidr_open" {
  type = string
}

variable "access_ip" {}


variable "alb_target" {
  default = {}
}

variable "alb_listener" {
  default = {}
}


variable "nginx_launch_template" {
  default = {}
}

variable "nginx_autoscaling" {
  default = {}
}

variable "public_key_path" {}

variable "key_name" {}

variable "cloudwatch" {
  default = {}
}

variable "kms_key_s3" {
  default = {}
}