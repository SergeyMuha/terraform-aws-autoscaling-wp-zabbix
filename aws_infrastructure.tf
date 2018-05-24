provider "aws" {
  region     = "us-east-1"
}
resource "aws_internet_gateway" "gwmuhas" {
  vpc_id = "${aws_vpc.vpcmuhas.id}"

  tags {
    Name = "muhas"
  }
}
resource "aws_vpc" "vpcmuhas" {
  cidr_block       = "192.168.0.0/24"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags {
    Name = "muhas"
  }
}

resource "aws_subnet" "subnetmuhas" {
  availability_zone = "us-east-1a"
  vpc_id     = "${aws_vpc.vpcmuhas.id}"
  cidr_block = "192.168.0.0/26"
  map_public_ip_on_launch = "true"

  tags {
    Name = "public_muhas"
  }
}

resource "aws_subnet" "subnetmuhass" {
  availability_zone = "us-east-1b"
  vpc_id     = "${aws_vpc.vpcmuhas.id}"
  cidr_block = "192.168.0.64/26"

  tags {
    Name = "private_muhas"
  }
}


resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.vpcmuhas.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.muhas.id}"
}

resource "aws_vpc_dhcp_options" "muhas" {
  domain_name          = "ec2.muhas"
  domain_name_servers  = ["AmazonProvidedDNS"]

  tags {
    Name = "muhas"
  }
}

resource "aws_default_route_table" "OutRouteMuhas" {
  default_route_table_id = "${aws_vpc.vpcmuhas.default_route_table_id}"

 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gwmuhas.id}"
  }


  tags {
    Name = "public_muhas"
  }
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.vpcmuhas.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gw.id}"
  }

  tags {
    Name = "muhas_private"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.subnetmuhass.id}"
  route_table_id = "${aws_route_table.r.id}"
}

resource "aws_eip" "ip" {
  vpc      = true
  tags {
    Name = "muhas"
  }

}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.ip.id}"
  subnet_id     = "${aws_subnet.subnetmuhas.id}"
  tags {
    Name = "muhas"
  }
}

resource "aws_default_security_group" "secgrmuhas" {
  vpc_id      = "${aws_vpc.vpcmuhas.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "muhas"
  }

}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.vpcmuhas.default_network_acl_id}"
  subnet_ids = ["${aws_subnet.subnetmuhas.id}"]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags {
    Name = "muhas"
  }
}


resource "aws_elb" "wp" {
  name               = "elb"
  subnets	      = ["${aws_subnet.subnetmuhas.id}","${aws_subnet.subnetmuhass.id}"]
  #availability_zones  = ["us-east-1a", "us-east-1b"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  tags {
    Name = "muhas"
  }
}

data "template_file" "zabbix" {
  template = "${file("${path.module}/zabbix.tpl")}"

}


data "template_file" "wp" {
  template = "${file("${path.module}/init.tpl")}"

  vars {
    databasedns = "${aws_db_instance.wordpressdb.endpoint}"
  }
  vars {
    lbdns = "${aws_elb.wp.dns_name}"

  }
  vars {
    zabbixdns = "${aws_instance.zabbix.public_dns}"
  }

  vars {
    zabbixip = "${aws_instance.zabbix.private_ip}"
  }


}

resource "aws_cloudwatch_metric_alarm" "up" {
  alarm_name          = "up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.wp.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.up.arn}"]
}

resource "aws_autoscaling_policy" "up" {
  name                   = "UPpolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = "${aws_autoscaling_group.wp.name}"
}


resource "aws_cloudwatch_metric_alarm" "down" {
  alarm_name          = "down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.wp.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.down.arn}"]
}

resource "aws_autoscaling_policy" "down" {
  name                   = "Downpolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = "${aws_autoscaling_group.wp.name}"
}


resource "aws_launch_configuration" "wp" {
  image_id      = "ami-38708b45"
  instance_type = "t2.micro"
  key_name 	= "terraformwp"
  security_groups = ["${aws_default_security_group.secgrmuhas.id}"]
  associate_public_ip_address = "false"
  user_data = "${data.template_file.wp.rendered}"
}

resource "aws_autoscaling_group" "wp" {
  max_size                  = 5
  min_size                  = 1
  launch_configuration = "${aws_launch_configuration.wp.name}"
  health_check_type         = "ELB"
  vpc_zone_identifier       = ["${aws_subnet.subnetmuhass.id}"]
  load_balancers = ["${aws_elb.wp.name}"]
  termination_policies = ["NewestInstance"]
  

}


resource "aws_instance" "bastion" {
  count = 1
  ami           = "ami-467ca739"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.subnetmuhas.id}"
  key_name      = "terraformwp"

  provisioner "file" {
    source      = "~/.ssh/terraformwp.pem"
    destination = "~/.ssh/terraformwp.pem"
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/terraformwp.pem")}"
    }
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("~/.ssh/terraformwp.pem")}"
    }
    inline = [
      "chmod 400 ~/.ssh/terraformwp.pem",
    ]
  }

  tags {
    Name = "bastion_host_muha"
  }
} 

resource "aws_instance" "zabbix" {
  count = 1
  ami           = "ami-38708b45"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.subnetmuhas.id}"
  key_name      = "terraformwp"
  user_data = "${data.template_file.zabbix.rendered}"

  provisioner "file" {
    source      = "~/.ssh/terraformwp.pem"
    destination = "~/.ssh/terraformwp.pem"
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file("~/.ssh/terraformwp.pem")}"
    }
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file("~/.ssh/terraformwp.pem")}"
    }
    inline = [
      "chmod 400 ~/.ssh/terraformwp.pem",
    ]
  }

  tags {
    Name = "zabbix_host_muha"
  }
}

output "Zabbix-host" {
  value = "${aws_instance.zabbix.public_dns}"
}


output "ELB host" {
  value = "${aws_elb.wp.dns_name}"
}

resource "aws_db_instance" "wordpressdb" {
  identifier = "dbinstance"
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "wordpress"
  username             = "wordpress"
  password             = "wordpress"
  db_subnet_group_name = "${aws_db_subnet_group.wp.id}"
  skip_final_snapshot     = "true"

  tags {
    Name = "muhas"
  }

}
resource "aws_db_subnet_group" "wp" {
  name       = "wp"
  subnet_ids = ["${aws_subnet.subnetmuhas.id}","${aws_subnet.subnetmuhass.id}"]

  tags {
    Name = "muhas"
  }
}
