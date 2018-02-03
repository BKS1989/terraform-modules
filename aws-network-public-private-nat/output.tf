output "AvailabilityZone" {
    value = ["${aws_subnet.public-subnet.*.availability_zone}"]
}
output "publicSubnet" {
    value = ["${aws_subnet.public-subnet.*.id}"]
}