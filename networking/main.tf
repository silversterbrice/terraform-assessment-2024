# ----  networking/main.tf -----


data "aws_availability_zones" "available" {}

resource "random_integer" "random" {
  min = 1
  max = 100
}

resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}


### VPC  ###
resource "aws_vpc" "gov_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "gov_vpc-${random_integer.random.id}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

### Public Subnet ###
resource "aws_subnet" "gov_public_subnet" {
  #count                   = length(var.public_cidrs)
  count                   = var.public_sn_count
  vpc_id                  = aws_vpc.gov_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  # availability_zone       = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"][count.index]
  #  availability_zone = data.aws_availability_zones.available.names[count.index]
  availability_zone = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "gov_public_${count.index + 1}"
  }
}


### Private Subnet ###
resource "aws_subnet" "gov_private_subnet" {
  # count                   = length(var.private_cidrs)
  count                   = var.private_sn_count
  vpc_id                  = aws_vpc.gov_vpc.id
  cidr_block              = var.private_cidrs[count.index]
  map_public_ip_on_launch = false
  # availability_zone       = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"][count.index]
  # availability_zone = data.aws_availability_zones.available.names[count.index]
  availability_zone = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "gov_private_${count.index + 1}"
  }
}


### Internet Gateway ###
resource "aws_internet_gateway" "gov_internet_gateway" {
  vpc_id = aws_vpc.gov_vpc.id

  tags = {
    Name = "gov_igw"
  }
}


### Public RT ###
resource "aws_route_table" "gov_public_rt" {
  vpc_id = aws_vpc.gov_vpc.id

  tags = {
    Name = "gov_public_RT"
  }
}


### Route for Public RT ###
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.gov_public_rt.id
  destination_cidr_block = var.cidr_open #"0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gov_internet_gateway.id
}


### Default RT ###
resource "aws_default_route_table" "gov_private_rt" {
  default_route_table_id = aws_vpc.gov_vpc.default_route_table_id

  tags = {
    Name = "gov_private_RT"
  }
}


### Associate Public Subnet with Public RT ###
resource "aws_route_table_association" "gov_public_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.gov_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.gov_public_rt.id
}


### Security group ###
resource "aws_security_group" "gov_sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.gov_vpc.id

  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}