# --- Compute/variables.tf ---


variable "launch_template" {
  default = {}
}

variable "autoscaling" {
  default = {}
}

variable "public_key_path" {
  type = string
}

variable "key_name" {
  default = {}
}

variable "lb_target_group_arn" {
  default = {}
}