## Note ##
Due to time constraint, I will keep this short.   
For any queries, please reach out to `divyang.jp@gmail.com`  
I appreciate your understanding!

## Infrastructure Architecture Diagram ##
<p align="center">
<img src="https://gitlab.com/divyang.jp/continotest/-/raw/86b7d2c920c89f59481e8671d744046607ba0236/Architecture-Diagram.png?inline=false">
</p>

## Solution Brief ##
There are two parts to this solution  
#### 1. AWS-TF-User : #### 
   This module creates terraforming user with necessary permission, S3 bucket for tfstate backup and dynamodb for state locking.  
Terraform apply this using admin level user.  
Once created, use `access-key-id` and `access-key-secret` of `terraforming-user` to create infrastructure in module `AWS-Terraform`  
`access-key-id` and `access-key-secret` can be fetched from terraform.tfstate local file

#### 2. AWS-Terraform : ####
   As per the `Architecture-Diagram`, this module will create infra in ap-southeast-2 (Sydney) region  
   * VPC (10.0.0.0/16)
   * Internet Gateway
   * One NAT-Gateway in one public subnet (can be in each for redundancy!)
   * Three public subnets in each availability zone
   * Three private subnets in each availability zone
   * Three EC2 instances in each private subnet
   * One jumphost EC2 instance for SSH access to private instances
   * Security groups and route tables

`terraform.tfstate` file is backed-up in S3 bucket (`continotest-terraform-state`) created as part of `AWS-TF-User` module

## How To Run ##

Configure Admin user `access_key` and `secret_key` using `aws` cli.  
Admin user is per-requisite and created manually before running this.

```
$ cd AWS-TF-User
$ terraform plan -out=terraform.tfplan
$ terraform apply -input=false terraform.tfplan 
```  
Now from `terraform.tfstate` file, get `id (access_key)` and `secret (secret_key)` for `terraforming-user`. Search for `aws_iam_access_key` in tfstate file for quick access  
  
Using `aws` cli, configure new profile for terraforming-user. Before running next steps, make sure `aws` cli profile is set to terraforming-user.  
Use below command to change default profile  
`$ export AWS_DEFAULT_PROFILE=<tf_user_profile>`

Next, infrastructure creation  

```
$ cd AWS-Terraform
$ terraform plan -out=terraform.tfplan
$ terraform apply -input=false terraform.tfplan
```

The `Outputs` should contain three instance IDs and key-pair map consisting of Public-key and Private-key. 


#### AGAIN - In case of queries, please reach out to `divyang.jp@gmail.com` ####
