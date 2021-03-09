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

# One intance per availability zone and private subnet
# Total 3
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

# One jumphost in public subnet to ssh into 
# instances in private subnets
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

output "instance-ids" {
  value = module.app-private-instances[*].ec2-instance-id
}

output "key-pair" {
  value = map(
    "public-key" , module.key-pair.public_key,
    "private-key" , module.key-pair.private_key
    )
}
