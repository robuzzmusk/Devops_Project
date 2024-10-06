provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "demo-server" {
    ami           = "ami-0866a3c8686eaeeba"
    instance_type = "t2.micro"
    key_name      = "terraform_key"
    vpc_security_group_ids = [aws_security_group.demo-sg.id]
    //security_groups = [ "demo-sg" ]
    subnet_id = aws_subnet.terraform_key-public-subnet-01.id
for_each = toset(["Jenkins-master", "Jenkins-build-slave", "ansible"])
   tags = {
      Name = "${each.key}"
    }
    //Reference the security group by its ID
    //vpc_security_group_ids = [aws_security_group.demo-sg.id]
}

resource "aws_security_group" "demo-sg" {
    name        = "demo-sg"
    description = "SSH Access"
    vpc_id = aws_vpc.terraform_key-vpc.id

    ingress { 
        description = "SSH Access"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress { 
        description = "Jenkins Port"
        from_port   = 8080
        to_port     = 8080
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
        Name = "ssh_port"
    }
}

resource "aws_vpc" "terraform_key-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "terraform_key-vpc"
  }
}

resource "aws_subnet" "terraform_key-public-subnet-01" {
  vpc_id = aws_vpc.terraform_key-vpc.id
  cidr_block = "10.1.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a"
  tags = {
    Name = "terraform_key-public-subnet-01"
  }
}

resource "aws_subnet" "terraform_key-public-subnet-02" {
  vpc_id = aws_vpc.terraform_key-vpc.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1b"
  tags = {
    Name = "terraform_key-public-subnet-02"
  }
}

resource "aws_internet_gateway" "terraform_key-igw" {
  vpc_id = aws_vpc.terraform_key-vpc.id
  tags = {
    Name = "terraform_key-igw"
  }
}

resource "aws_route_table" "terraform_key-rt" {
  vpc_id = aws_vpc.terraform_key-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_key-igw.id
  }
}

resource "aws_route_table_association" "terraform_key-rta-public-subnet-01" {
    subnet_id = aws_subnet.terraform_key-public-subnet-01.id
    route_table_id = aws_route_table.terraform_key-rt.id
}

resource "aws_route_table_association" "terraform_key-rta-public-subnet-02" {
    subnet_id = aws_subnet.terraform_key-public-subnet-02.id
    route_table_id = aws_route_table.terraform_key-rt.id
} 

 module "sgs" {
    source = "../sg_eks"
    vpc_id     =     aws_vpc.terraform_key-vpc.id
 }

  module "eks" {
       source = "../eks"
       vpc_id     =     aws_vpc.terraform_key-vpc.id
       subnet_ids = [aws_subnet.terraform_key-public-subnet-01.id,aws_subnet.terraform_key-public-subnet-02.id]
       sg_ids = module.sgs.security_group_public
 }
