### Define the variables ###
variable "ami" {
  default = ""
}

variable "instance_type" {
  default = ""
}

variable "name_tag" {
  default = ""
}

variable "availability_zone" {
  default = ""
}

variable "subnet_name" {
  default = null
}

variable "key_name" {
  default = ""
}

### Data blocks ###

data "aws_subnet" "this" {
  filter {
    name = "tag:Name"
    values = ["${var.subnet_name}"]
  }
}

### Provision a Private Key and an EC2 instance ###
resource "aws_instance" "this" {
  ami               = var.ami
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  subnet_id         = var.subnet_name == "" ? null : data.aws_subnet.this.id
  key_name          = var.key_name
  tags = {
    Name = var.name_tag
  }
}

### Define the outputs ###
output "ec2-instance-id" {
  value = aws_instance.this.id
}

output "ec2-instance-name" {
  value = var.name_tag
}