#Core VPC configuration

resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true #this is required for RDS endpoint resolver  
    tags = {
        Name = "${var.project_name}-vpc"
    }
}


# Internet Gateway — the "door" that lets traffic flow between
# the VPC and the public internet. One per VPC.

resource "aws_internet_gateway" "main"{
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.project_name}-igw"
    }
}


# --- PUBLIC SUBNETS (for ALB + EC2) ---
# count = 2 creates two of these, one per AZ, using the CIDR list
# and AZ list defined in variables.tf. This is how you get high
# availability: if one AZ (data center) goes down, the other still
# serves traffic.


resource "aws_subnet" "public" {
    count             =  length(var.public_subnet_cidrs)
    vpc_id            = aws_vpc.main.id
    cidr_block        = var.public_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.project_name}-public-${var.availability_zones[count.index]}"
    }
}


#--- Private SUBNETS (for RDS) ---
resource "aws_subnet" "private" {
    count           = length(var.private_subnet_cidrs)
    vpc_id          = aws_vpc.main.id
    cidr_block      = var.private_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]

    # No mapping of public IP because this for private SUBNETS

    tags = {
        Name = "${var.project_name}-private-${var.availability_zones[count.index]}"

    }
}



# Route table for public subnets: "any traffic (0.0.0.0/0) goes out
# through the Internet Gateway"

resource "aws_route_table" "public" {
     vpc_id = aws_vpc.main.id

     route {
        cidr_block  = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
     }

     tags = {
        Name = "${var.project_name}-public-rt"
     }
}


# Attach that route table to both public subnets

resource "aws_route_table_association" "public"{
    count     = length(aws_subnet.public)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id 
}


# NOTE: private subnets are left on the VPC's default (main) route
# table, which has NO internet route. That's intentional — RDS
# doesn't need internet access, and this is what keeps it private
# without paying for a NAT Gateway (~$32/month we're avoiding).