# Terraform Infrastructure Module

This Terraform module provides a complete infrastructure setup including compute, networking, security, monitoring, and load balancing components in AWS.

## Modules and Components created

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
