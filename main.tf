provider "aws" {
  region = "eu-central-1"
  shared_credentials_files = ["$HOME/.aws/credentials"]
  profile                 = "gaming-tf"
}

resource "aws_vpc" "reforger_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "reforger_subnet"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.reforger_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.reforger_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_internet_gateway" "reforger_gw" {
  vpc_id = aws_vpc.reforger_vpc.id

  tags = {
    Name = "reforger-IGW"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.reforger_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.reforger_gw.id
  }

  tags = {
    Name = "reforger-RT"
  }
}

resource "aws_route_table_association" "subnet-RT-association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "reforger_secgroup" {
  vpc_id = aws_vpc.reforger_vpc.id

  ingress {
    from_port   = 19999
    to_port     = 19999
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "RCON"
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["3.120.181.40/29"]
    description = "EC2 Connect"
  }
  
  ingress {
    from_port   = 2001
    to_port     = 2001
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Clients Connect"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "reforger-server-SG"
  }
}

resource "aws_instance" "reforger_ec2" {
  ami = "ami-0e04bcbe83a83792e" // Ubuntu eu-central-1
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1a"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.reforger_secgroup.id]

  tags = {
    Name = "reforger-server"
  }

}
