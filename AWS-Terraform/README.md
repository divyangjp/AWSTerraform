# Scenario:

The Application team requires 2 EC2 instances to be provisioned. They have already written a module for EC2 instances.
Your job is to reuse the `ec2` and `key-pair` modules to provision 3 instances with the following properties passed in as input parameters:

- Instance Type: `t3.micro`
- Tags: Add a `Name` tag that is unique for each instance.

It has also been decided that each EC2 instance needs to be provisioned in the following Availability Zones and Subnets.

| Subnet | Availability Zone |
|--------|-------------------|
| subnet-az-2a | ap-southeast-2a |
| subnet-az-2b | ap-southeast-2b |
| subnet-az-2c | ap-southeast-2c |

<br>

Also output the following values:

1. A list of all Instance IDs.
2. The Public and Private key of the Key Pair as a Map

<br>

## Deliverables:

1. Write a clear and understandable README.md file which details deployment process, any input parameters and any outputs.
2. A `private` repository with the code.
3. A blueprint Terraform file that uses the modules to provision the resources.

<br>

## Extras:

You can either code or explain how the following could be accomplished:

1. CI/CD pipeline for deployment to a Terraform Cloud workspace.
2. Any tests to check for success or failure of the pipeline.