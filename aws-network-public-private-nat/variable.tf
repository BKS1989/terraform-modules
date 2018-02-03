
variable "aws_region" {
    default = "us-west-2"
}

variable "aws_access_key_id" {
    //default = "<your key>"
}

variable "aws_secret_access_key" {
    //default = "<your key>"
}

variable "ProvisionInternetGateway" {
    description = "if you want to Create Internet Gateway"
    default = true
}

variable "ProvisionNAT" {
    description = "if you are using nat to route traffic between instance"
    default = true
}

variable "PrivateSubnet" {
    description = "private subnet route"
    type = "list"
    default = ["SplunkMaster","SplunkSearchHead","SplunkIndexer"]
}

variable "cidr_block" {
    description = "if you want to Create Internet Gateway"
    default = "10.0.0.0/16"
}

variable "tags" {
    description = "Create Tag for Resource"
    type = "map"
    default = {
        "environment" = "development"
        "profile" = "dev"
    }
}
