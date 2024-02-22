# Assessment Overview

This document provides an overview of the assessment project's implementation, which involves creating a repository, developing local Terraform modules, and setting up a GitHub Actions pipeline for automation.

## Creating Repository

The assessment project begins with creating a new repository on GitHub. This repository serves as the central location for storing the project's codebase, including Terraform configurations, local modules, and pipeline configuration files.

## Developing Local Terraform Modules

Local Terraform modules are developed to modularize the infrastructure components. Each module encapsulates specific functionality, such as networking, load balancing, compute, monitoring, and security. These modules are stored within the project repository and can be reused across different environments or projects.

## Setting Up GitHub Actions Pipeline

To automate various tasks in the assessment workflow, a GitHub Actions pipeline is configured. This pipeline automates processes such as linting, testing, and deployment of Terraform modules. The pipeline is defined using YAML configuration files and is stored within the project repository.

## Getting Started

To begin with the assessment project:

1. Create a new repository on GitHub.
2. Develop local Terraform modules to modularize infrastructure components.
3. Configure and set up a GitHub Actions pipeline to automate workflow tasks.



# Terraform Infrastructure Overview

This Terraform module provides a complete infrastructure setup including compute, networking, security, monitoring, and load balancing components in AWS.

## Modules and resources created

- **Compute**: Provision EC2 instances with Key pair, Launch template, Autoscaling group and Target group attachment.
- **Networking**: Create VPC, subnets, Public/Private route tables, routes, Security group and internet gateway.
- **Security**: Setup Guard duty.
- **Monitoring**: Set up CloudWatch dashboard, log group and Cloudtrail.
- **Load Balancing**: Configure Application Load Balancer with HTTP/HTTPS listeners and ACM.

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) version 1.7.3 installed.
- [Visual Studio Code](https://code.visualstudio.com/) for editing Terraform configurations.
- [Git Bash](https://gitforwindows.org/) for running Git commands on Windows.
- AWS credentials configured.

## Terraform Module Overview

This repository contains Terraform modules for managing various aspects of AWS infrastructure, including networking, load balancing, compute, monitoring, and security.


```hcl
module "networking" {
  source           = "./networking"
  vpc_cidr         = var.cidr
  max_subnets      = var.max_subnets
  private_sn_count = var.private_sn_counts
  public_sn_count  = var.public_sn_counts
  private_cidrs    = [for i in range(1, 255, 2) : cidrsubnet("${var.cidr}", 8, i)]
  public_cidrs     = [for i in range(2, 255, 2) : cidrsubnet("${var.cidr}", 8, i)]
  cidr_open        = var.cidr_open
  security_groups  = local.security_groups
}

module "loadbalancing" {
  source = "./loadbalancing"

   vpc_id = module.networking.vpc_id

  aws_lb = {
    name               = var.aws_lb.name
    idle_timeout       = var.aws_lb.idle_timeout
    internal           = var.aws_lb.internal
    load_balancer_type = var.aws_lb.load_balancer_type
    subnets            = module.networking.public_subnets
    security_groups    = module.networking.public_sg
  }

  lb_target_group = {
    port                = var.alb_target.port
    protocol            = var.alb_target.protocol
    healthy_threshold   = var.alb_target.healthy_threshold
    unhealthy_threshold = var.alb_target.unhealthy_threshold
    timeout             = var.alb_target.timeout
    interval            = var.alb_target.interval
  }

  lb_listener = {
    port        = var.alb_listener.port
    protocol    = var.alb_listener.protocol
    status_code = var.alb_listener.status_code
  }

  lb_listener_https = {
    port       = var.lb_listener_https.port
    protocol   = var.lb_listener_https.protocol
    ssl_policy = var.lb_listener_https.ssl_policy
  }

  acm = {
    domain_name       = var.acm.domain_name
    validation_method = var.acm.validation_method
  }
}


module "compute" {
  source = "./compute"

  public_key_path = var.public_key_path
  key_name        = var.key_name

  launch_template = {
    name                   = var.nginx_launch_template.name
    device_name            = var.nginx_launch_template.device_name
    volume_size            = var.nginx_launch_template.volume_size
    vpc_security_group_ids = module.networking.public_sg
    image_id               = var.nginx_launch_template.image_id
    instance_type          = var.nginx_launch_template.instance_type
  }

  autoscaling = {
    name                = var.nginx_autoscaling.name
    vpc_zone_identifier = [module.networking.public_subnets[0], module.networking.public_subnets[1]] 
    desired_capacity    = var.nginx_autoscaling.desired_capacity
    max_size            = var.nginx_autoscaling.max_size
    min_size            = var.nginx_autoscaling.min_size
    target_group_arns   = module.loadbalancing.target_group_arn
    health_check_type   = var.nginx_autoscaling.health_check_type
    refresh_strategy    = var.nginx_autoscaling.refresh_strategy
    health_percentage   = var.nginx_autoscaling.health_percentage
  }

  lb_target_group_arn = module.loadbalancing.target_group_arn[0]
}


module "monitoring" {
  source = "./monitoring"

  cloudwatch = {
    dashboard_name    = var.cloudwatch.dashboard_name
    dashboard_body    = file("files/dashboard_config.json")
    log_group         = var.cloudwatch.log_group
    retention_in_days = var.cloudwatch.retention_in_days
  }

  kms_key_s3 = {
    description             = var.kms_key_s3.description #"KMS key for S3 encryption"
    deletion_window_in_days = var.kms_key_s3.deletion_window_in_days
    enable_key_rotation     = var.kms_key_s3.enable_key_rotation
    bucket                  = var.kms_key_s3.bucket        #"gov-cloudtrail-monitoring-2024"
    sse_algorithm           = var.kms_key_s3.sse_algorithm #"aws:kms"
    cloudtrail_name         = var.kms_key_s3.cloudtrail_name
    s3_key_prefix           = var.kms_key_s3.s3_key_prefix
    enable_logging          = var.kms_key_s3.enable_logging
    force_destroy           = var.kms_key_s3.force_destroy
    object_ownership        = var.kms_key_s3.object_ownership
    acl                     = var.kms_key_s3.acl
  }
  template_file_path = "./files/cloudtrail_bucket_policy.json.tpl" // S3 bucket policy for cloudtrail
}


module "Security" {
  source = "./security"

  guardduty_enable = true
}
```

# Terraform GitHub Actions Pipeline

This repository includes a GitHub Actions pipeline for managing Terraform infrastructure deployments.

## Workflow Details

The GitHub Actions pipeline is triggered on pushes to the `main` branch. It performs the following tasks:

- **Checkout**: Clones the repository to the GitHub Actions runner.
- **Install Dependencies**: Installs dependencies required for the Terraform deployment, including `jq` for JSON parsing.
- **Retrieve CIDR**: Executes a script to retrieve a CIDR block. If successful, sets the CIDR as an output for later use.
- **Terraform Init**: Initializes Terraform using the specified version (1.7.3) and working directory (`.`).
- **Terraform Plan**: Plans the Terraform deployment, optionally passing the retrieved CIDR block as a variable if available.

## Pipeline Configuration

```yaml
name: Terraform

on:
  push:
    branches: [ "main" ]

jobs:
  terraform:
    name: Terraform
    env:
      # AWS secrets
      AWS_ACCESS_KEY_ID: ${{ secrets.DEMO_AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.DEMO_AWS_SECRET_ACCESS_KEY }}

    runs-on: ubuntu-latest
    environment: production

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq
      
      - name: Grant execute permission to retrieve_cidr.sh
        run: chmod +x files/retrieve_cidr.sh

      - name: Retrieve CIDR
        id: get_cidr
        run: |
          if ./files/retrieve_cidr.sh; then
            CIDR=$(cat cidr.txt)
            echo "::set-output name=cidr::$CIDR"
          else
            echo "::set-output name=cidr::"
          fi

      - name: Terraform Init
        uses: hashicorp/terraform-github-actions@master
        with:
          tf_actions_version: 1.7.3
          tf_actions_subcommand: 'init'
          tf_actions_working_dir: '.'
          tf_actions_comment: true

      - name: Terraform plan
        run: |
          if [ -n "${{ steps.get_cidr.outputs.cidr }}" ]; then
            terraform plan -var "cidr=${{ steps.get_cidr.outputs.cidr }}"
          else
            terraform plan
          fi
