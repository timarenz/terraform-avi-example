terraform {
  backend "local" {}
}

provider "aws" {}

module "vpc" {
  source           = "github.com/timarenz/terraform-aws-vpc"
  environment_name = "${var.environment_name}"
}

module "avicontroller" {
  source = "github.com/timarenz/terraform-aws-avicontroller"

  public_key       = "${file("avi.key.pub")}"
  subnet_id        = "${module.vpc.vpc_public_subnet_id}"
  password         = "${var.password}"
  environment_name = "${var.environment_name}"
  cluster          = false
}

module "perf_server_client" {
  source = "github.com/timarenz/terraform-aws-perf-server-client"

  public_subnet_id  = "${module.vpc.vpc_public_subnet_id}"
  private_subnet_id = "${module.vpc.vpc_private_subnet_id}"
  environment_name  = "${var.environment_name}"
}
