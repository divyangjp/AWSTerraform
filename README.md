## Note ##
Due to time constraint, I will keep this short.  
For any queries, please reach out to `divyang.jp@gmail.com`  
I appreciate your understanding!  

## Prerequisites ##
Machine with
  * AWS CLI
  * Kubectl CLI
  * aws-iam-authenticator
  * Terraform (>v0.14)
 
All these packages are standard and available across Linux and MacOS

## Infrastructure Architecture Diagram ##
<p align="center">
<img src="https://gitlab.com/divyang.jp/estimateone/-/raw/master/Architecture-Diagram.png?inline=false">
</p>

## Solution Brief ##
There are three parts to this solution
#### 1. AWS-TF-User : ####
   This module creates terraforming user with necessary permission, S3 bucket for tfstate backup and dynamodb for state locking.
Terraform apply this using admin level user.  
Once created, use `access-key-id` and `access-key-secret` of `terraforming_user` to create infrastructure in module `AWS-Terraform`  
`access-key-id` and `access-key-secret` can be fetched from terraform.tfstate local file  

#### 2. AWS-Terraform : ####
   As per the `Architecture-Diagram`, this module will create infra in ap-southeast-2 (Sydney) region
   * VPC (10.0.0.0/16)
   * Internet Gateway
   * One NAT-Gateway in one public subnet (can be in each for redundancy!)
   * Three public subnets in each availability zone
   * Three private subnets in each availability zone
   * EKS Kubernetes Cluster backed by EC2 Autoscaling group
   * Autoscaling group spans across three private subnets in three availability zones for redundancy and fault-tolenrance
   * One jumphost EC2 instance for SSH access to private k8s instances
   * Security groups and route tables
   * ELB loadbalancer as part of Nginx sample app
  
#### 3. k8s : ####
  Sample nginx kubernetes deployment and service.  
  Nginx service is exposed as `LoadBalancer` which creates ELB in AWS infra.  

IMP: `terraform.tfstate` file is backed-up in S3 bucket created as part of `AWS-TF-User` module  

## How To Run ##

Configure Admin user `access_key` and `secret_key` using `aws` cli.  
Admin user is per-requisite and created manually before running this.  

```
$ cd AWS-TF-User
$ terraform plan -var 's3-bucket-tfstate-store=<UNIQUE-S3-BUCKET-NAME>' -out=terraform.tfplan
$ terraform apply -input=false terraform.tfplan
```
Once applied, open `terraform.tfstate` file. Get `id (access_key)` and `secret (secret_key)` for `terraforming_user`. Search for `aws_iam_access_key` in tfstate file for quick access to `id` and `secret` values.  

Using `aws` cli, configure new profile for `terraforming_user`. Before running next steps, make sure `aws` cli profile is set to terraforming_user.  
```$ aws configure --profile=tf_user```
Use below command to change default profile
```$ export AWS_DEFAULT_PROFILE=tf_user```

> One IMPORTANT step before proceeding further  
```sh
# Open AWS-Terraform/backend-config.tfvars file
# Replace `bucket` value with the <UNIQUE-S3-BUCKET-NAME> selected earlier
# Save and close the file
```
> Next, infrastructure creation
```sh
$ cd AWS-Terraform
$ terraform init -backend-config=backend-config.tfvars
$ terraform plan -out=terraform.tfplan
$ terraform apply -input=false terraform.tfplan

# Apply will take approx 10-15 minutes
```

The `Outputs` will contain key-pair map consisting of Public-key and Private-key.  
This key-pair can be used to `SSH` into Jumphost VM  

A `kubeconfig_eksdev` file is created in `AWS-Terraform` directory.  
Using it, `terraforming_user` can access kubernetes cluster.  

> Next, creating Nginx deployment in k8s cluster  
```sh
$ cd AWS-Terraform
$ cp ./kubeconfig_eksdev ~/.kube/config
$ cd ..
$ kubectl apply -f ./k8s/

# ELB creation might take some time. Check progress using
$ kubectl get svc
```
Once ELB is created, service `nginxdepservice` will have `ExternalIP` assigned which will look something like `a7bd84f8bf0a643c38fbb385cc91ef98-1487056810.ap-southeast-2.elb.amazonaws.com`  
Open your favorite browser and copy/paste the `ExternalIP` value in the url.  
Hit Enter and it should open default Nginx page!  

`terraform.tfstate` file is backed up in S3 bucket `<UNIQUE-S3-BUCKET-NAME>`  

I would have loved to create CI/CD pipeline for this, but due to time-contstraint couldn't work on it!  

#### AGAIN - In case of queries, please reach out to `divyang.jp@gmail.com` ####
