# Terraform configuration block to define provider requirements and Terraform version

# Defines the required providers for this Terraform configuration
terraform {
  required_providers {
    # Specifies the AWS provider settings
    aws = {
      source  = "hashicorp/aws" # Defines the source of the AWS provider
      version = ">=5.40.0"      # Specifies that the AWS provider version must be at least 5.40.0
    }
  }

  # Specifies the required Terraform version for this configuration
  required_version = "~> 1.7" # This configuration is compatible with Terraform versions approximately 1.7.x
}
