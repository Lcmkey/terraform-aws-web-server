# Reference

- [AWS Provider][AWS-Provider]
- [Terraform Course][freeCodeCamp.org]

# Steps
1. Create Vpc
2. Create Internet Gatway
3. Create Custom Route Table
4. Create a Subet
5. Associatesubnte with Route Table
6. Create Security Group to allow port 22, 80, 443
7. Create a network interface with an ip in the subnet that waws created in step 4
8. Assign an elastic IP to the network interface created in step 7
9. Create Ubuntu server and install/enable apache2
 
# Othters

Destroy one stack

    $ terraform destroy --target aws_instance.wev-server-instance

Create one Stack

    $ terraform apply --target aws_instance.wev-server-instance

Create Single Stack With Param

    $ terraform apply -var "subnet-prefix=10.178.1.0/24"

Create Single Stack With varfile

    $ terraform apply -var-file example.tfvars

<!-- Reference -->

[AWS-Provider]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
[freeCodeCamp.org]: https://www.youtube.com/watch?v=SLB_c_ayRMo