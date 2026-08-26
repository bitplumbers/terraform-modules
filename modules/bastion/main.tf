terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Network Interface
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_network_interface" "bastion" {
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.bastion.id]

  tags = merge(
    {
      Name = "${var.name}-eni"
    },
    var.tags
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# EC2 Instance
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  user_data_content = var.user_data != null ? var.user_data : file("${path.module}/user-data.sh")
}
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t4g.nano"
  user_data_replace_on_change = true

  primary_network_interface {
    network_interface_id = aws_network_interface.bastion.id
  }

  iam_instance_profile = aws_iam_instance_profile.bastion.name

  root_block_device {
    volume_size = var.root_volume_size
    encrypted   = true
  }

  user_data = local.user_data_content

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# Security Group
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "bastion" {
  name        = "${var.name}-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  # No inbound rules needed as we're using SSM

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    {
      Name = "${var.name}-sg"
    },
    var.tags
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Role and Instance Profile
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "bastion" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name}-profile"
  role = aws_iam_role.bastion.name
}

# ---------------------------------------------------------------------------------------------------------------------
# CloudWatch Log Group
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "bastion" {
  name              = "/aws/ssm/${var.name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# SSM Parameter for Instance ID
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ssm_parameter" "bastion_instance_id" {
  name  = "/bastion/${var.name}/instance-id"
  type  = "String"
  value = aws_instance.bastion.id

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# Route53 Record
# ---------------------------------------------------------------------------------------------------------------------

data "aws_route53_zone" "bastion" {
  zone_id = var.route53_zone_id
}

resource "aws_route53_record" "bastion" {
  zone_id = data.aws_route53_zone.bastion.zone_id
  name    = "bastion-${var.name}.${data.aws_route53_zone.bastion.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.bastion.private_ip]
}
