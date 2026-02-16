resource "local_file" "hosts" {
  content = templatefile("${path.module}/hosts.tpl",
    {
      bast_ip          = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
      web01_hostname   = yandex_compute_instance.web01.hostname
      web02_hostname   = yandex_compute_instance.web02.hostname
      zabbix_hostname  = yandex_compute_instance.zabbix.hostname
      kibana_hostname  = yandex_compute_instance.kib.hostname
      elastic_hostname = yandex_compute_instance.elk.hostname
    }
  )
  filename = "${path.module}/ansible/hosts.cfg"
}