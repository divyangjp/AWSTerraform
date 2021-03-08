data "aws_subnet_ids" "private_subs" {
  vpc_id = module.network.vpc-id

  tags = {
    Tier = "Private"
  }
}
