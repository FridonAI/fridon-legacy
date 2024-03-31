provider "aws" {
  region = "eu-central-1"
  profile = "dfl"
}

data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "eip" {
  instance = aws_instance.fridon-instance.id
  domain   = "vpc"
}

resource "aws_instance" "fridon-instance" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"

  security_groups = [aws_security_group.allow_web.name]

  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              sudo yum update -y
              yum install -y docker
              sudo service docker start
              sudo systemctl enable docker

              # Add the ec2-user to the docker group so you can execute Docker commands without using sudo
              sudo usermod -a -G docker ec2-user

              # Install Docker Compose
              # Download the desired version of Docker Compose (replace the version number if necessary)
              sudo curl -L "https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

              # Apply executable permissions to the binary
              sudo chmod +x /usr/local/bin/docker-compose
              docker-compose version
              EOF

  tags = {
    Name = "FridonAi"
  }
}