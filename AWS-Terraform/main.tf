#data "aws_subnet_ids" "private_subs" {
#  vpc_id = network.vpc-id
#
#  tags = {
#    type = "Private"
#  }
#}

data "aws_ami" "ubuntu-1604" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

#module "network" {
#  source = "./modules/network"
#  azones = local.availability_zones
#  rgroup = "ctest"
#}

module "app-private-instances" {
  source = "./modules/ec2"
  count = length(aws_subnet.private_subnet)
  ami = data.aws_ami.ubuntu-1604.id
  instance_type = "t3.micro"
  subnet_name = aws_subnet.private_subnet[count.index].tags["Name"]
  security_group_ids = [aws_security_group.allow_ssh_in_vpc.id,
                       aws_security_group.default.id]
  key_name = module.key-pair.key-name
  name_tag = "AppInst0${count.index + 1}"
}

# Jumphost to access instances in private subnet
module "app-jumphost" {
  source = "./modules/ec2"
  count = 1
  ami = data.aws_ami.ubuntu-1604.id
  instance_type = "t3.micro"
  subnet_name = aws_subnet.public_subnet[0].tags["Name"]
  security_group_ids = [aws_security_group.allow_ssh.id,
                       aws_security_group.default.id]
  key_name = module.key-pair.key-name
  name_tag = "app-jumphost"
}

module "key-pair" {
  source = "./modules/key-pair"
  key_name = "ctest-key-pair"
}
