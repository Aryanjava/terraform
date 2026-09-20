# --- ALB Security Group ---
#Faces the public internet on port 80 (HTTP)

resource "aws_security_group" "alb" {
        name        =  "${var.project_name}-alb-sg"
        description =  "Allow inbound Http traffic from the Internet"
        vpc_id      =  aws_vpc.main.id

        
        ingress {
            description = "HTTP from Anywhere"
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"] 
        }

        egress {
            description = "Allow all outbound"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"] 
        }

        tags = { Name = "${var.project_name}-alb-sg" }
        

}


# --- EC2 Security Group ---
# Only trusts traffic FROM the ALB's security group on port 80,
# plus SSH from your own IP for management.


resource "aws_security_group" "ec2" {
    name          = "${var.project_name}-ec2-sg"
    description   = "Allow HTTP traffic only from Alb, and SSH from admin ID for troublshooting"
    vpc_id        = aws_vpc.main.id

    ingress {
       description     = "HTTP from Alb only"
       from_port       = 80
       to_port         = 80
       protocol        = "tcp"
       security_groups = [aws_security_group.alb.id] # <- Key line: source is a SG

    }

    ingress {
        description   = "SSH from the admin IP"
        from_port     = 22
        to_port       = 22
        protocol      = "tcp"
        cidr_blocks   = [var.allowed_ssh_cidr]
    }

    egress {
        description   = "Allow all outbound"
        from_port     = 0
        to_port       = 0
        protocol      = "-1"
        cidr_blocks   = ["0.0.0.0/0"]
    }

    tags = { Name = "${var.project_name}-ec2-sg" }
}



# --- RDS Security Group ---
# Only trusts traffic FROM the EC2 security group on the MySQL port.
# Nothing on the internet can reach the database directly.

resource "aws_security_group" "rds" {
           name         = "${var.project_name}-rds-sg"
           description  = "Allow Mysql Only from EC2 instances"
           vpc_id       = aws_vpc.main.id


           ingress {
            description      = "MySQL from EC2 only"
            from_port        = 3306
            to_port          = 3306
            protocol         = "tcp"
            security_groups  = [aws_security_group.ec2.id]
           }

           egress {
            description      = "Allow All outbound" 
            from_port        = 0
            to_port          = 0
            protocol         = "-1"
            cidr_blocks      = ["0.0.0.0/0"]
           }

           tags = { Name = "${var.project_name}-rds-sg" }
}