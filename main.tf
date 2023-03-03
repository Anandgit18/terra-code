# configured aws provider with proper credentials
provider "aws" {
    region = "ap-south-1"
    access_key = "AKIATMW4RMT4OXB5SNK7"
    secret_key = "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"
}

resource "aws_key_pair" "terra-key" {
    key_name = "terrakey"
    public_key = file("terrakey.pub")
}

resource "aws_vpc" "terra-vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    tags = {
        Name = "terra"
    }
}

resource "aws_subnet" "terra_subnet" {
    vpc_id = aws_vpc.terra.vpc_id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "ap-south-1a"
    tags = {
        Name = "terra-pub-subnet"
    } 
}

resource "aws_security_group" "terra_sg" {
    name        = "terra-sg"
    description = "Allow TLS inbound traffic"
    vpc_id      = aws_vpc.terra.id
  
    ingress {
      description      = "TLS from VPC"
      from_port        = 85
      to_port          = 85
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
    tags = {
      Name = "terra-sg"
    }
}

resource "aws_instance" "terra" {
    ami = "ami-09ba48996007c8b50"
    instance_type = "t2.micro"
    availability_zone = "ap-south-1a"
    key_name = aws_key_pair.terra-key.key_name
    tags = {
        Name = "terra-server"
    }
    
 provisioner "file" {
    source = "web.sh"
    destination = "C:/DevOps/Terraformterraformfile/web.sh"
 }

 provisioner "remote-exec"{

    inline = [
        "sudo chmod +x C:/DevOps/Terraformterraformfile/web.sh"
        "sudo C:/DevOps/Terraformterraformfile/web.sh"
    ]
 }
 
 connection {
    user = "ec2-user"
    private_key = file("terrakey")
    host = aws_instance.terra.public_ip
 }
}

# print the url of the container server
output "container_url" {
  value = join("", ["http://", aws_instance.terra.public_dns])
}
