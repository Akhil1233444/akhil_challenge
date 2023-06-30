terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
tls = {
source = "hashicorp/tls"
version = "3.3.0"
}

}
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  profile = var.profile_name
}

# Create a VPC
resource "aws_vpc" "app_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "app-vpc"
  }
}




resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "vpc_igw"
  }
}




# Subnets : public
resource "aws_subnet" "public" {
  count = length(var.public_subnets_cidr)
  vpc_id = aws_vpc.app_vpc.id
  cidr_block = element(var.public_subnets_cidr,count.index)
  availability_zone = element(var.azs,count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet-${count.index+1}"
  }
}


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_rt_asso" {
  count = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public.*.id,count.index)
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_instance" "web" {
  count = length(var.public_subnets_cidr)
  ami           = "ami-026ebd4cfe2c043b2" 
  instance_type = var.instance_type
  key_name = var.instance_key
  subnet_id              = element(aws_subnet.public.*.id,count.index)
  security_groups = [aws_security_group.sg.id]


  user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing httpd" > /var/log/messages
  sudo yum install httpd -y > /var/log/messages
  sudo systemctl start httpd
  echo "<html><head><title>Hello World</title></head><body><h1>Hello World!</h1></body></html>" | sudo tee /var/www/html/test.html
  >/etc/httpd/conf.d/welcome.conf
  sudo systemctl restart httpd
  echo "*** Completed Installing httpd"
  sudo yum install mod_ssl openssl -y
  sudo openssl genrsa -out ca.key 2048
  sudo openssl req -new -key ca.key -out ca.csr  -subj "/C=US/ST=KY/L=Lo/O=Global Security/OU=IT/CN=ca.com"  
  sudo openssl x509 -req -days 365 -in ca.csr -signkey ca.key -out ca.crt

  sudo cp ca.crt /etc/pki/tls/certs
  sudo cp ca.key /etc/pki/tls/private/ca.key
  sudo cp ca.csr /etc/pki/tls/private/ca.csr
  
  sed -i "s/SSLCertificate/#SSLCertificate/g"  /etc/httpd/conf.d/ssl.conf
  echo "SSLCertificateFile /etc/pki/tls/certs/ca.crt" >> /etc/httpd/conf.d/ssl.conf
  echo "SSLCertificateKeyFile /etc/pki/tls/private/ca.key" >> /etc/httpd/conf.d/ssl.conf
  
  sed -i "s/#DocumentRoot/DocumentRoot/g" /etc/httpd/conf.d/ssl.conf
  sed -i "s/#ServerName www.example.com/ServerName localhost/g" /etc/httpd/conf.d/ssl.conf

  EOF

  

  tags = {
    Name = "web_instance"
  }

  volume_tags = {
    Name = "web_instance"
  } 
}

terraform {
  required_version = ">= 0.11.5"
}

resource "time_sleep" "wait_seconds" {
  create_duration = "60s"
}

