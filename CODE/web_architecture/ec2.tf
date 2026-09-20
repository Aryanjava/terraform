# We use a `data` source to look up the latest
# Amazon Linux 2023 AMI instead of hardcoding an AMI ID. AMI IDs
# are region-specific and change over time — hardcoding one is a
# classic beginner mistake that breaks your code in 6 months or in
# a different region.

data "aws_ami" "amazon_linux" {
          most_recent = true
          owners       = ["amazon"]

          filter {
            name = "name"
            values = ["al2023-ami-*-x86_64"] 
          }

          filter {
            name = "virtualization-type"
            values = ["hvm"]
          }
}



# Simple startup script: installs a web server and serves a page
# that identifies WHICH instance answered. This is invaluable for
# proving to yourself the load balancer is actually distributing
# traffic across both instances (refresh the ALB URL and watch the
# instance ID change).


locals {
    user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable httpd
    systemctl start httpd
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    echo "<h1> Namaste from $${INSTANCE_ID} in $${AZ} </h1>" > /var/www/html/index.html
    EOF
}

resource "aws_instance" "web" {
        count                  = 2
        ami                    = data.aws_ami.amazon_linux.id
        instance_type          = var.instance_type
        subnet_id              = aws_subnet.public[count.index].id
        vpc_security_group_ids = [aws_security_group.ec2.id]
        key_name               = var.key_name != "" ? var.key_name : null
        user_data              = local.user_data

        tags = {
            Name = "${var.project_name}-web-${count.index + 1}"
        } 
}