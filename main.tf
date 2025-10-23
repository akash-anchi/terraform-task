terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

# AWS Providers for two regions
provider "aws" {
  alias  = "use2"
  region = "us-east-2"
}

provider "aws" {
  alias  = "usw1"
  region = "us-west-1"
}

# Common variables
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# AMI mapping (latest kernel 6.12 for each region)
locals {
  amis = {
    "us-east-2" = "ami-0432d6eb1918ce708"
    "us-west-1" = "ami-0237ec7e824e87c71"
  }
}

# Get default VPCs
data "aws_vpc" "default_use2" {
  provider = aws.use2
  default  = true
}

data "aws_vpc" "default_usw1" {
  provider = aws.usw1
  default  = true
}

# Security Groups
resource "aws_security_group" "sg_use2" {
  provider    = aws.use2
  name        = "allow-ssh-use2"
  description = "Allow SSH in us-east-2"
  vpc_id      = data.aws_vpc.default_use2.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-use2"
  }
}

resource "aws_security_group" "sg_usw1" {
  provider    = aws.usw1
  name        = "allow-ssh-usw1"
  description = "Allow SSH in us-west-1"
  vpc_id      = data.aws_vpc.default_usw1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ssh-usw1"
  }
}

# EC2 Instances (no key_name)
resource "aws_instance" "instance_use2" {
  provider              = aws.use2
  ami                   = local.amis["us-east-2"]
  instance_type         = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg_use2.id]

  tags = {
    Name   = "tf-instance-use2"
    Region = "us-east-2"
  }
}

resource "aws_instance" "instance_usw1" {
  provider              = aws.usw1
  ami                   = local.amis["us-west-1"]
  instance_type         = var.instance_type
  vpc_security_group_ids = [aws_security_group.sg_usw1.id]

  tags = {
    Name   = "tf-instance-usw1"
    Region = "us-west-1"
  }
}

# Outputs
output "instance_details" {
  value = {
    "us-east-2" = {
      id        = aws_instance.instance_use2.id
      public_ip = aws_instance.instance_use2.public_ip
      ami       = aws_instance.instance_use2.ami
    }
    "us-west-1" = {
      id        = aws_instance.instance_usw1.id
      public_ip = aws_instance.instance_usw1.public_ip
      ami       = aws_instance.instance_usw1.ami
    }
  }
}
