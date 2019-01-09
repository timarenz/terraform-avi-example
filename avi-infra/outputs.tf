output "public_ip" {
  value = "${module.avicontroller.public_ip}"
}

output "private_subnet_name" {
  value = "${module.vpc.vpc_private_subnet_name}"
}

output "private_subnet_az" {
  value = "${module.vpc.vpc_private_subnet_az}"
}

output "private_subnet_id" {
  value = "${module.vpc.vpc_private_subnet_id}"
}

output "private_subnet_cidr" {
  value = "${module.vpc.vpc_private_subnet_cidr}"
}

output "public_subnet_name" {
  value = "${module.vpc.vpc_public_subnet_name}"
}

output "public_subnet_az" {
  value = "${module.vpc.vpc_public_subnet_az}"
}

output "public_subnet_id" {
  value = "${module.vpc.vpc_public_subnet_id}"
}

output "public_subnet_cidr" {
  value = "${module.vpc.vpc_public_subnet_cidr}"
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vpc_name" {
  value = "${module.vpc.vpc_name}"
}

output "vpc_region" {
  value = "${module.vpc.vpc_region}"
}

output "server_private_ips" {
  value = "${module.perf_server_client.server_private_ips}"
}
