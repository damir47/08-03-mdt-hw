# Web servers
output "internal_ip_address_web_01" {
  description = "Internal IP of web01"
  value       = yandex_compute_instance.web01.network_interface.0.ip_address
}

output "internal_ip_address_web_02" {
  description = "Internal IP of web02"
  value       = yandex_compute_instance.web02.network_interface.0.ip_address
}

output "external_ip_address_web" {
  description = "External IP of the web ALB"
  value       = yandex_alb_load_balancer.alb-web.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

# Zabbix
output "internal_ip_address_zbx_01" {
  description = "Internal IP of zabbix"
  value       = yandex_compute_instance.zabbix.network_interface.0.ip_address
}

output "external_ip_address_zbx_01" {
  description = "External IP of zabbix"
  value       = yandex_compute_instance.zabbix.network_interface.0.nat_ip_address
}

# Bastion
output "internal_ip_address_bst_01" {
  description = "Internal IP of bastion"
  value       = yandex_compute_instance.bastion.network_interface.0.ip_address
}

output "external_ip_address_bst_01" {
  description = "External IP of bastion"
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

# Kibana
output "internal_ip_address_kib-1" {
  description = "Internal IP of kib"
  value       = yandex_compute_instance.kib.network_interface.0.ip_address
}

output "external_ip_address_kib-1" {
  description = "External IP of kib"
  value       = yandex_compute_instance.kib.network_interface.0.nat_ip_address
}

# Elasticsearch
output "internal_ip_address_elk_01" {
  description = "Internal IP of elk"
  value       = yandex_compute_instance.elk.network_interface.0.ip_address
}

output "hostnames" {
  description = "All hostnames"
  value = {
    web01   = yandex_compute_instance.web01.hostname
    web02   = yandex_compute_instance.web02.hostname
    zabbix  = yandex_compute_instance.zabbix.hostname
    kib     = yandex_compute_instance.kib.hostname
    elk     = yandex_compute_instance.elk.hostname
    bastion = yandex_compute_instance.bastion.hostname
  }
}

output "ssh_commands" {
  description = "SSH connection commands"
  value = {
    bastion   = "ssh user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} -i ~/.ssh/ansible"
    to_web01  = "ssh -J user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} user@${yandex_compute_instance.web01.hostname}.ru-central1.internal -i ~/.ssh/ansible"
    to_web02  = "ssh -J user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} user@${yandex_compute_instance.web02.hostname}.ru-central1.internal -i ~/.ssh/ansible"
    to_zabbix = "ssh -J user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} user@${yandex_compute_instance.zabbix.hostname}.ru-central1.internal -i ~/.ssh/ansible"
    to_kib    = "ssh -J user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} user@${yandex_compute_instance.kib.hostname}.ru-central1.internal -i ~/.ssh/ansible"
    to_elk    = "ssh -J user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} user@${yandex_compute_instance.elk.hostname}.ru-central1.internal -i ~/.ssh/ansible"
  }
}

output "web_interfaces" {
  description = "Web interfaces URLs"
  value = {
    alb    = "http://${yandex_alb_load_balancer.alb-web.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}"
    zabbix = "http://${yandex_compute_instance.zabbix.network_interface.0.nat_ip_address}/zabbix"
    kibana = "http://${yandex_compute_instance.kib.network_interface.0.nat_ip_address}:5601"
  }
}