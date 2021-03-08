data "aws_subnet_ids" "private_subs" {
  vpc_id = module.network.vpc-id

  tags = {
    type = "Private"
  }
}

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

module "network" {
  
}

module "app-instances" {
  source = "./modules/ec2"
  for_each = data.aws_subnet_ids.private_sub.ids
  ami = "${data.aws_ami.ubuntu-1604.id}"
  instance_type = "t3.micro"
  subnet_name = each.value
  key-name = "${module.key-pair.key-name}"
  name_tag = "AppInst0${index(data.aws_subnet_ids.private_subs.ids, each.value) + 1}"
}

module "key-pair" {
  source = "./modules/key-pair"
  key_name = "ctest-key-pair"
}
