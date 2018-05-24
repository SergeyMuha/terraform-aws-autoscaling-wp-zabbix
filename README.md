# terraform-aws-autoscaling-wp
Use this template to setup aws infrastructure DB ELB autoscaling ... with wordpress site

Requirements:
AWS-cli with configured AWS Access Key ID and AWS Secret Access Key -- use https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-linux.html 
https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html

How to :

Create aws key-pair

###### aws ec2 create-key-pair --key-name terraformwp --query 'KeyMaterial' --output text > ~/.ssh/terraformwp.pem

###### chmod 400 ~/.ssh/terraformwp.pem

###### mkdir somedir

###### cd somedir

###### git clone https://github.com/SergeyMuha/terraform-aws-autoscaling-wp.git

###### cd terraform-aws-autoscaling-wp-zabbix

###### terraform init

Deploy infrastructure. This command will output dns name for haproxy and bastion 

###### terraform apply -input=false -auto-approve

Go to browser to zabbix-host dns to end zabbix setup

ex.
Outputs:

Zabbix-host = ec2-18-206-90-206.compute-1.amazonaws.com
 
## password for DB qwerty
## name for host ec2-18-206-90-206.compute-1.amazonaws.com
## user - Admin password - zabbix

Configure zabbix for autodiscovery

![Alt text](https://drive.google.com/file/d/1BpnZbP-CI9xgfdaf36xwK1_Xb2nzSDRR/view?usp=sharing "Step 1")
![Alt text](https://drive.google.com/file/d/1dhmbzF2077omG85eRAqKuNpykWEN9w4l/view?usp=sharing "Step 2")

Check in browser  elb dns name 

To destroy infrastructure use 

###### terraform destroy -input=false -auto-approve

