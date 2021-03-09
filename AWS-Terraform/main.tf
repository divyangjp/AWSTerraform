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

module "app-instances" {
  source = "./modules/ec2"
  #for_each = data.aws_subnet_ids.private_subs.ids
  #for_each = aws_subnet.private_subnet
  count = length(aws_subnet.private_subnet)
  ami = data.aws_ami.ubuntu-1604.id
  instance_type = "t3.micro"
  subnet_name = aws_subnet.private_subnet[count.index].tags["Name"]
  key_name = module.key-pair.key-name
  #name_tag = "AppInst0${index(aws_subnet.private_subnet, each.value) + 1}"
  name_tag = "AppInst0${count.index + 1}"
}

module "key-pair" {
  source = "./modules/key-pair"
  key_name = "ctest-key-pair"
}
