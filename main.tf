provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}

/**
* Define Variables
*/
variable "subnet_prefix" {
    description = "cidr block for the subnet"
    # type = String
    # default = "10.178.22.0/24"
}

/**
* EC2
*/
# resource "aws_instance" "ec2-sam-dev" {
#   ami           = "ami-063e3af9d2cc7fe94"
#   instance_type = "t2.micro"

#   tags = {
#     Name = "ubuntu-sam"
#   }
# }

/**
* VPC
*/
# resource "aws_vpc" "vpc-sam-dev" {
#   cidr_block = "10.178.0.0/16"

#   tags = {
#     Name = "development"
#   }
# }

# resource "aws_vpc" "vpc-sam-prod" {
#   cidr_block = "10.179.0.0/16"

#   tags = {
#     Name = "production"
#   }
# }

/**
* Vpc Subnet
*/
# resource "aws_subnet" "subnet-1" {
#   vpc_id     = aws_vpc.vpc-sam-dev.id
#   cidr_block = "10.178.1.0/24"

#   tags = {
#     Name = "dev-subet"
#   }
# }

# resource "aws_subnet" "subnet-2" {
#   vpc_id     = aws_vpc.vpc-sam-prod.id
#   cidr_block = "10.179.1.0/24"

#   tags = {
#     Name = "prod-subet"
#   }
# }

# 1. Create Vpc

resource "aws_vpc" "vpc-sam-dev" {
  cidr_block = "10.178.0.0/16"

  tags = {
    Name = "development"
  }
}

# 2. Create Internet Gatway
resource "aws_internet_gateway" "gw-sam-dev" {
  vpc_id = aws_vpc.vpc-sam-dev.id

  tags = {
    Name = "gw-sam-dev"
  }
}

# 3. Create Custom Route Table
resource "aws_route_table" "rt-sam-dev" {
  vpc_id = aws_vpc.vpc-sam-dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw-sam-dev.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw-sam-dev.id
    # egress_only_gateway_id = aws_internet_gateway.gw-sam-dev.id
  }

  tags = {
    Name = "Dev"
  }
}

# 4. Create a Subet
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.vpc-sam-dev.id
#   cidr_block = "10.178.1.0/24"
  cidr_block = var.subnet_prefix[0].cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_prefix[0].name
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.vpc-sam-dev.id
#   cidr_block = "10.178.1.0/24"
  cidr_block = var.subnet_prefix[1].cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_prefix[0].name
  }
}


# 5. Associatesubnte with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.rt-sam-dev.id
}

# 6. Create Security Group to allow port 22, 80, 443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.vpc-sam-dev.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip in the subnet that waws created in step 4
resource "aws_network_interface" "web-server-nic-dev" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.178.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic-dev.id
  associate_with_private_ip = "10.178.1.50"
  depends_on = [aws_internet_gateway.gw-sam-dev]
}

# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "wev-server-instance" {
    ami = "ami-0ac80df6eff0e70b5"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "terraform-test-sam"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic-dev.id
    }
    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
    tags = {
        Name = "web-server"
    }
}

# output
output "server_public_ip" {
    value = aws_eip.one.public_ip
}
output "server_private_ip" {
    value = aws_instance.wev-server-instance.private_ip
}
output "server_id" {
    value = aws_instance.wev-server-instance.id
}