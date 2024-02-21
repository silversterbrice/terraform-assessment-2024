
### AWS Guardduty ###
resource "aws_guardduty_detector" "gov_guardduty" {
  enable = var.guardduty_enable

  datasources {
    s3_logs {
      enable = var.guardduty_enable
    }
  
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.guardduty_enable
        }
      }
    }
  }
}