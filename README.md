# Terraform Infrastructure Module

This Terraform module provides a complete infrastructure setup including compute, networking, security, monitoring, and load balancing components in AWS.

## Components created

- **Compute**: Provision EC2 instances with Key pair, Launch template, Autoscaling group and Target group attachment.
- **Networking**: Create VPC, subnets, Public/Private route tables, routes, Security group and internet gateway.
- **Security**: Setup Guard duty.
- **Monitoring**: Set up CloudWatch dashboard, log group and Cloudtrail.
- **Load Balancing**: Configure Application Load Balancer with HTTP and HTTPS listeners.

## Usage

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) version 1.7.3 installed.
- [Visual Studio Code](https://code.visualstudio.com/) for editing Terraform configurations.
- [Git Bash](https://gitforwindows.org/) for running Git commands on Windows.
- AWS credentials configured.

### Module Structure

The module is organized into several directories:

- `compute`: Contains Terraform configuration for EC2 instances.
- `networking`: Defines VPC, subnets, and routing configurations.
- `security`: Manages security groups and IAM roles.
- `monitoring`: Sets up CloudWatch alarms and logging.
- `loadbalancing`: Configures Application Load Balancer and listeners.
