resource "yandex_compute_snapshot_schedule" "snapshot" {
  name = "snapshot"

  schedule_policy {
    expression = "0 10 * * *"
  }

  retention_period = "168h"

  snapshot_count = 7

  snapshot_spec {
    description = "snapshot"
  }

  disk_ids = [
    "${yandex_compute_instance.bastion.boot_disk.0.disk_id}",
    "${yandex_compute_instance.web01.boot_disk.0.disk_id}",
    "${yandex_compute_instance.web02.boot_disk.0.disk_id}",
    "${yandex_compute_instance.zabbix.boot_disk.0.disk_id}",
    "${yandex_compute_instance.kib.boot_disk.0.disk_id}",
    "${yandex_compute_instance.elk.boot_disk.0.disk_id}", ]
}