# --- networking/outputs.tf ---


output "vpc_id" {
  value = aws_vpc.gov_vpc.id
}


output "public_sg" {
  value = aws_security_group.gov_sg["public"].id
}

output "public_subnets" {
  value = aws_subnet.gov_public_subnet.*.id
}