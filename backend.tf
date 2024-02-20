terraform {
  backend "s3" {
    bucket = "nginx-terraform-demo-silversterbrice-2024"
    key    = "nginx-terraform-demo-silversterbrice.tfstate"
    region = "ap-southeast-1"
  }
}