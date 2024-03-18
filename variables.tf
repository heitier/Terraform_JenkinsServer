# Define the name of the security group. This security group allows traffic on ports 22 and 8080.
variable "security_group_name" {
  description = "Allows Traffic on port 22 and 8080"
  type        = string
  default     = "terraform-JenkinsApp_server-sg"
}

# Define the CIDR blocks for HTTP and SSH ingress rules. 
# This determines who can access the resources associated with these rules.
variable "cidr_block" {
  description = "CIDR blocks for HTTP and SSH ingress rules"
  type        = list(string)
  default     = ["172.124.77.72/32"] # Change this to your IP / CIDR block
}

# User data script to be executed on EC2 instance initialization. 
# This script installs Jenkins and configures the server.
variable "user_data" {
  default = <<-EOF
               #!/bin/bash
               # Download and add the Jenkins repository key
               sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
               https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
               # Add Jenkins repository to the sources list
               echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
               https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
               /etc/apt/sources.list.d/jenkins.list > /dev/null
               # Update packages and install Jenkins
               sudo apt update
               sudo apt -y upgrade
               sudo apt-get -y install fontconfig openjdk-17-jre
               sudo apt-get -y install jenkins
               # Set hostname and reboot the server
               sudo hostnamectl set-hostname terraform_project
               sudo reboot
               EOF
}

# Define the service that is allowed to assume the IAM role. Typically used for service roles.
variable "service" {
  description = "The service that can assume this role"
  type        = string
  default     = "ec2.amazonaws.com"
}

# Define the name of the IAM role that will be created.
variable "role_name" {
  description = "The name of the IAM role"
  type        = string
  default     = "S3-FullAccess-4-Jenkins"
}
