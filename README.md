# terraform-aws-autoscaling-wp-zabbix
Use this template to setup aws infrastructure DB, ELB, Autoscaling group, Launch config, VPC and all network infrastructure. Automatically deploy wordpress site and setup zabbix server for monitoring.

Requirements:
AWS-cli with configured AWS Access Key ID and AWS Secret Access Key -- use https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-linux.html 
https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html

How to :

Create aws key-pair

###### aws ec2 create-key-pair --key-name terraformwp --query 'KeyMaterial' --output text > ~/.ssh/terraformwp.pem

###### chmod 400 ~/.ssh/terraformwp.pem

###### mkdir somedir

###### cd somedir

###### git clone https://github.com/SergeyMuha/terraform-aws-autoscaling-wp-zabbix.git

###### cd terraform-aws-autoscaling-wp-zabbix/

###### terraform init

Deploy infrastructure. This command will output dns name for haproxy and bastion 

###### terraform apply -input=false -auto-approve

Open in  browser  zabbix-host-dns to end zabbix setup

ex.
Outputs:

Zabbix-host = ec2-18-206-90-206.compute-1.amazonaws.com
 
###### password for DB - qwerty
###### name for host ec2-18-206-90-206.compute-1.amazonaws.com
###### user - Admin, password - zabbix

Configure zabbix for autodiscovery

![Alt text](https://www.kinokut.com/wp-content/uploads/2018/05/Capture1.png "Step 1")
![Alt text](https://www.kinokut.com/wp-content/uploads/2018/05/Capture2.png "Step 2")

Open in browser  elb-dns-name 

To destroy infrastructure use 

###### terraform destroy -input=false -auto-approve

