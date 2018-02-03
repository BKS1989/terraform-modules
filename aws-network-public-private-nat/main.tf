provider "aws" {
    region = "${var.aws_region}"
    access_key = "${var.aws_access_key_id}"
    secret_key = "${var.aws_secret_access_key}"
}

data "aws_availability_zones" "available" {}

resource  "aws_vpc" "vpc" {
    cidr_block = "${var.cidr_block}"
    tags {
        Name = "${var.tags["environment"]}-${var.tags["profile"]}-vpc"
        Environment  = "${var.tags["environment"]}"  
    }
}

resource "aws_subnet" "public-subnet" {
    vpc_id = "${aws_vpc.vpc.id}"
    count = "${length(data.aws_availability_zones.available.names)}"
    cidr_block = "${cidrsubnet(var.cidr_block, 8, count.index+1)}"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    map_public_ip_on_launch = "true"
    tags {
        Name = "${var.tags["environment"]}-${var.tags["profile"]}-${data.aws_availability_zones.available.names[count.index]}-pubnet"
        Environment  = "${var.tags["environment"]}"  
    } 
}

resource "aws_internet_gateway" "internet-gateway" {
    count = "${var.ProvisionInternetGateway ? 1 : 0 }"
    vpc_id = "${aws_vpc.vpc.id}"
    tags {
        Name = "${var.tags["environment"]}-${var.tags["profile"]}-ig"
        Environment  = "${var.tags["environment"]}"  
    }
}

resource "aws_route_table" "public-route-table" {
    count = "${var.ProvisionInternetGateway ? 1 : 0 }"
    vpc_id = "${aws_vpc.vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.internet-gateway.id}"
    }
    tags {
        Name = "${var.tags["environment"]}-${var.tags["profile"]}-pubroutetable"
        Environment  = "${var.tags["environment"]}"
    }
}

resource "aws_route_table_association" "public-route-association" {
    count = "${length(data.aws_availability_zones.available.names)}"
    subnet_id = "${element(aws_subnet.public-subnet.*.id,count.index)}"
    route_table_id = "${aws_route_table.public-route-table.id}"
}

### private subnet setting ###################
resource "aws_eip" "eip" {
    count = "${var.ProvisionNAT ? 1 : 0 }"
    vpc = true
    tags = {
        Name = "${var.tags["environment"]}-${var.tags["profile"]}-eip"
        Environment  = "${var.tags["environment"]}"
    }
}

resource "aws_nat_gateway" "nat-gw" {
    count = "${var.ProvisionNAT ? 1 : 0 }"
    allocation_id = "${aws_eip.eip.id}"
    subnet_id = "${element(aws_subnet.public-subnet.*.id,0)}"
    depends_on = [
        "aws_internet_gateway.internet-gateway"
    ]
}

resource "aws_route_table" "private-route-table" {
    count = "${var.ProvisionNAT ? 1 : 0 }"
    vpc_id = "${aws_vpc.vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_nat_gateway.nat-gw.id}"
    }
    tags {
        Name = "${var.tags["environment"]}-${var.tags["profile"]}-privateroutetable"
        Environment  = "${var.tags["environment"]}"
    }
}

locals {
    subnet_range = "${length(data.aws_availability_zones.available.names)+1}"
}
resource "aws_subnet" "private-subnet" {
    vpc_id = "${aws_vpc.vpc.id}"
    count = "${length(var.PrivateSubnet)}"
    cidr_block = "${cidrsubnet(var.cidr_block, 8, local.subnet_range+count.index+1)}"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    map_public_ip_on_launch = "true"
    tags {
        Name = "${var.tags["environment"]}-${var.tags["profile"]}-${data.aws_availability_zones.available.names[0]}-${var.PrivateSubnet[count.index]}"
        Environment  = "${var.tags["environment"]}"  
    } 
}
resource "aws_route_table_association" "private-route-association" {
    count = "${length(var.PrivateSubnet)}"
    subnet_id = "${element(aws_subnet.private-subnet.*.id,count.index)}"
    route_table_id = "${aws_route_table.private-route-table.id}"
}