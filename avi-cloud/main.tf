terraform {
  backend "local" {}
}

data "terraform_remote_state" "avi_infrastructure" {
  backend = "local"

  config {
    path = "../avi-infra/terraform.tfstate"
  }
}

provider "avi" {
  avi_username   = "admin"
  avi_tenant     = "admin"
  avi_password   = "${var.password}"
  avi_controller = "${data.terraform_remote_state.avi_infrastructure.public_ip}"
  avi_version    = "17.2.7"
}

data "avi_tenant" "default" {
  name = "admin"
}

data "avi_vrfcontext" "global" {
  name      = "global"
  cloud_ref = "${avi_cloud.aws.id}"
}

resource "avi_cloud" "aws" {
  name         = "AWS-Cloud"
  vtype        = "CLOUD_AWS"
  dhcp_enabled = true
  license_tier = "ENTERPRISE_18"
  license_type = "LIC_CORES"
  tenant_ref   = "${data.avi_tenant.default.id}"

  aws_configuration {
    region        = "${data.terraform_remote_state.avi_infrastructure.vpc_region}"
    vpc           = "${data.terraform_remote_state.avi_infrastructure.vpc_name}"
    vpc_id        = "${data.terraform_remote_state.avi_infrastructure.vpc_id}"
    use_iam_roles = true

    zones {
      availability_zone = "${data.terraform_remote_state.avi_infrastructure.private_subnet_az}"
      mgmt_network_name = "${data.terraform_remote_state.avi_infrastructure.private_subnet_name}"
      mgmt_network_uuid = "${data.terraform_remote_state.avi_infrastructure.private_subnet_id}"
    }
  }
}

resource "avi_serviceenginegroup" "default" {
  name                 = "Default-Group"
  cloud_ref            = "${avi_cloud.aws.id}"
  max_se               = 4
  buffer_se            = 0
  se_deprovision_delay = 1
  instance_flavor      = "c5.large"
  license_tier         = "ENTERPRISE_18"
  license_type         = "LIC_CORES"
  se_bandwidth_type    = "SE_BANDWIDTH_UNLIMITED"
  max_vs_per_se        = 20
  vcpus_per_se         = 2
  se_name_prefix       = "${var.environment_name}"
  tenant_ref           = "${data.avi_tenant.default.id}"

  realtime_se_metrics {
    duration = 0
    enabled  = true
  }
}
