terraform {
  backend "local" {}
}

data "terraform_remote_state" "avi_infrastructure" {
  backend = "local"

  config {
    path = "../avi-infra/terraform.tfstate"
  }
}

data "terraform_remote_state" "avi_cloud" {
  backend = "local"

  config {
    path = "../avi-cloud/terraform.tfstate"
  }
}

provider "avi" {
  avi_username   = "admin"
  avi_tenant     = "admin"
  avi_password   = "${var.password}"
  avi_controller = "${data.terraform_remote_state.avi_infrastructure.public_ip}"
  avi_version    = "17.2.7"
}

data "avi_healthmonitor" "http" {
  name = "System-HTTP"
}

data "avi_applicationpersistenceprofile" "http_cookie" {
  name = "System-Persistence-Http-Cookie"
}

data "avi_applicationprofile" "secure_http" {
  name = "System-Secure-HTTP"
}

data "avi_wafpolicy" "default" {
  name = "System-WAF-Policy"
}

data "avi_sslprofile" "default" {
  name = "System-Standard"
}

data "avi_sslkeyandcertificate" "default" {
  name = "System-Default-Cert-EC"
}

resource "avi_server" "webservers" {
  count = "${length(data.terraform_remote_state.avi_infrastructure.server_private_ips)}"
  ip = "${element(data.terraform_remote_state.avi_infrastructure.server_private_ips, count.index)}"
  port = "80"
  pool_ref = "${avi_pool.aws.id}"
} 

resource "avi_pool" "aws" {
  name         = "aws-pool"
  tenant_ref   = "${data.terraform_remote_state.avi_cloud.tenant}"
  cloud_ref    = "${data.terraform_remote_state.avi_cloud.cloud}"
  vrf_ref      = "${data.terraform_remote_state.avi_cloud.vrf}"
  server_count = 2

  application_persistence_profile_ref = "${data.avi_applicationpersistenceprofile.http_cookie.uuid}"

  health_monitor_refs = ["${data.avi_healthmonitor.http.uuid}"]

  # servers {
  #   ip = {
  #     type = "V4"
  #     addr = "${data.terraform_remote_state.avi_infrastructure.server_private_ips.0}"
  #   }

  #   hostname          = "${data.terraform_remote_state.avi_infrastructure.server_private_ips.0}"
  #   availability_zone = "${data.terraform_remote_state.avi_infrastructure.private_subnet_az}"

  #   discovered_networks = {
  #     network_ref = "https://${data.terraform_remote_state.avi_infrastructure.public_ip}/api/network/${data.terraform_remote_state.avi_infrastructure.private_subnet_id}"

  #     subnet = {
  #       ip_addr = {
  #         addr = "${element(split("/", data.terraform_remote_state.avi_infrastructure.private_subnet_cidr), 0)}"
  #         type = "V4"
  #       }

  #       mask = "${element(split("/", data.terraform_remote_state.avi_infrastructure.private_subnet_cidr), 1)}"
  #     }
  #   }
  # }

  # servers {
  #   ip = {
  #     type = "V4"
  #     addr = "${data.terraform_remote_state.avi_infrastructure.server_private_ips.1}"
  #   }

  #   hostname          = "${data.terraform_remote_state.avi_infrastructure.server_private_ips.1}"
  #   availability_zone = "${data.terraform_remote_state.avi_infrastructure.private_subnet_az}"

  #   discovered_networks = {
  #     network_ref = "https://${data.terraform_remote_state.avi_infrastructure.public_ip}/api/network/${data.terraform_remote_state.avi_infrastructure.private_subnet_id}"

  #     subnet = {
  #       ip_addr = {
  #         addr = "${element(split("/", data.terraform_remote_state.avi_infrastructure.private_subnet_cidr), 0)}"
  #         type = "V4"
  #       }

  #       mask = "${element(split("/", data.terraform_remote_state.avi_infrastructure.private_subnet_cidr), 1)}"
  #     }
  #   }
  # }
}

resource "avi_virtualservice" "aws" {
  name            = "aws-vs"
  cloud_type      = "CLOUD_AWS"
  pool_ref        = "${avi_pool.aws.id}"
  tenant_ref      = "${data.terraform_remote_state.avi_cloud.tenant}"
  cloud_ref       = "${data.terraform_remote_state.avi_cloud.cloud}"
  vrf_context_ref = "${data.terraform_remote_state.avi_cloud.vrf}"

  se_group_ref = "${data.terraform_remote_state.avi_cloud.se_group}"

  application_profile_ref      = "${data.avi_applicationprofile.secure_http.uuid}"
  waf_policy_ref               = "${data.avi_wafpolicy.default.uuid}"
  ssl_profile_ref              = "${data.avi_sslprofile.default.uuid}"
  ssl_key_and_certificate_refs = ["${data.avi_sslkeyandcertificate.default.uuid}"]

  vip {
    vip_id                    = "0"
    auto_allocate_ip          = true
    avi_allocated_vip         = true
    auto_allocate_floating_ip = true
    avi_allocated_fip         = true
    availability_zone         = "${data.terraform_remote_state.avi_infrastructure.public_subnet_az}"
    subnet_uuid               = "${data.terraform_remote_state.avi_infrastructure.public_subnet_id}"

    subnet = {
      ip_addr = {
        addr = "${element(split("/", data.terraform_remote_state.avi_infrastructure.public_subnet_cidr), 0)}"
        type = "V4"
      }

      mask = "${element(split("/", data.terraform_remote_state.avi_infrastructure.public_subnet_cidr), 1)}"
    }
  }

  services {
    enable_ssl     = false
    port           = 80
    port_range_end = 80
  }

  services {
    enable_ssl     = true
    port           = 443
    port_range_end = 443
  }

  analytics_policy {
    enabled         = true
    client_insights = "PASSIVE"

    full_client_logs = {
      enabled     = true
      all_headers = true
      duration    = 0
    }

    metrics_realtime_update = {
      enabled  = true
      duration = 0
    }
  }
}
