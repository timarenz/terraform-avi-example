output "public_ip" {
  value = "${avi_virtualservice.aws.vip.0.floating_ip.0.addr}"
}
