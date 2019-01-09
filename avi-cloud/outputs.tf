output "tenant" {
  value = "${avi_cloud.aws.tenant_ref}"
}

output "cloud" {
  value = "${avi_cloud.aws.id}"
}

output "se_group" {
  value = "${avi_serviceenginegroup.default.id}"
}

output "vrf" {
  value = "${data.avi_vrfcontext.global.id}"
}
