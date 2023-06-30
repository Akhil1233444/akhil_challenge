variable "region" {
default = "us-east-1"
}
variable "instance_type" {
default = "t2.micro"
}
variable "profile_name" {
default = "default"
}
variable "instance_key" {
default = "comcast"
}
variable "vpc_cidr" {
default = "178.0.0.0/16"
}
#variable "public_subnet_cidr" {
#default = "178.0.10.0/24"
#}
variable "public_subnets_cidr" {
	type = list
	default = ["178.0.10.0/24", "178.0.20.0/24"]
}

variable "azs" {
	type = list
	default = ["us-east-1a", "us-east-1b"]
}

