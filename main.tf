# Configure the AWS provider with the specified region
provider "aws" {
  region = "us-east-1"
}

# Retrieve the most recent Ubuntu AMI that matches the specified filters
data "aws_ami" "ubuntu" {
  most_recent = true

  # Filter for Ubuntu images
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  # Ensure the virtualization type is HVM (Hardware Virtual Machine)
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Specify the owner of the AMI
  owners = ["099720109477"]
}

# Create a security group for Jenkins application with specific ingress and egress rules
resource "aws_security_group" "sg_JenkinsApp" {
  name        = var.security_group_name
  description = "Allow traffic on port 8080 and 22"

  # Allow incoming SSH connections
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_block
  }

  # Allow incoming traffic on port 8080
  ingress {
    description = "Allow port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.cidr_block
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_port_22_8080"
  }
}

# Generate an RSA key pair for the Jenkins server
resource "aws_key_pair" "Jenkins_server_key" {
  key_name   = "Jenkins_server_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

# Generate a private RSA key of 4096 bits
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store the generated private key in a local file
resource "local_file" "TFjenkins_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "Jenkins_server_key.pem"
}

# Create an AWS EC2 instance for Jenkins
resource "aws_instance" "JenkinsApp_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_JenkinsApp.id]
  user_data              = var.user_data
  key_name               = aws_key_pair.Jenkins_server_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.IAM_profile_lab.name

  tags = {
    Name = "Jenkins EC2 server"
  }
}

# Create an IAM role with a policy that allows assuming the role
resource "aws_iam_role" "S3-FullAccess-4-Jenkins" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = var.service
        }
      },
    ]
  })
}

# Attach the Amazon S3 full access policy to the IAM role
resource "aws_iam_policy_attachment" "s3_full_access" {
  name       = "s3_full_access"
  roles      = [aws_iam_role.S3-FullAccess-4-Jenkins.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create a profile to attach the IAM role
resource "aws_iam_instance_profile" "IAM_profile_lab" {
  name = "IAM_profile_lab"
  role = aws_iam_role.S3-FullAccess-4-Jenkins.name
}

# Create an S3 bucket for storing Jenkins artifacts
resource "aws_s3_bucket" "jenkins-bucket" {
  bucket = "luit-jenkins-artifact-bucket"
}
