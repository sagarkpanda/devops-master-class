terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.47.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

resource "aws_default_vpc" "default_vpc" {

}

//HTTP Server -> SG group
//80 TCP(HTTP), 22 TCP (SSH), CIDR [0.0.0.0/0]

resource "aws_security_group" "http_server_sg" {
  name = "http_server_sg"
  # vpc_id = "vpc-41d3b63c"
  vpc_id = aws_default_vpc.default_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    name = "http_server_sg"
  }

}

resource "aws_instance" "http_server" {
  # ami                    = "ami-0ab4d1e9cf9a1215a"
  ami                    = data.aws_ami.aws_linux_2_latest.id
  key_name               = "default-ec2"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.http_server_sg.id]
  # subnet_id              = "subnet-b7622ad1"
  subnet_id = tolist(data.aws_subnet_ids.default_subnets.ids)[0]


  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.aws_key_pair)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y",                                                               //install httpd (http server)
      "sudo service httpd start",                                                                //start the server
      "echo Welcome to EC2, Server is at ${self.public_dns} | sudo tee /var/www/html/index.html" //copy a file
    ]
  }


}
 