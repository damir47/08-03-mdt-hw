#считываем данные об образе ОС
data "yandex_compute_image" "ubuntu_2404_lts" {
  family = "ubuntu-2404-lts-oslogin"
}

#Создание VM
resource "yandex_compute_instance" "vm-yc-web-lab" {
  count = 2
  name        = "vm-yc-web-lab${count.index}" 
  hostname    = "vm-yc-web-lab${count.index}"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = var.websrv.cores
    memory        = var.websrv.memory
    core_fraction = var.websrv.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.websrv.drive_size
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.web1.id
    nat                = true
  }
}
#Создаем облачную сеть
resource "yandex_vpc_network" "web1" {
  name = "web1"
}

#Создаем подсеть web1
resource "yandex_vpc_subnet" "web1" {
  name           = "web1"
  network_id     = yandex_vpc_network.web1.id
  v4_cidr_blocks = ["10.32.1.0/24"]
}

#Создаем группу балансировки
resource "yandex_lb_target_group" "lbgroup1" {
  name = "lbgroup1"

  dynamic "target" {
    for_each = yandex_compute_instance.vm-yc-web-lab
    content {
      subnet_id = yandex_vpc_subnet.web1.id
      address = target.value.network_interface.0.ip_address
    }
  }
}

#Создам балансировщик
resource "yandex_lb_network_load_balancer" "lb1" {
  name = "lb1"
  deletion_protection = "false"
  listener {
    name = "mdt-lb1"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  #Подключаем группу балансировки к балансировщику
  attached_target_group {
    target_group_id = yandex_lb_target_group.lbgroup1.id
    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}