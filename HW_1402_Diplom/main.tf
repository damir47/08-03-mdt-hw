#считываем данные об образе ОС
data "yandex_compute_image" "ubuntu_2404_lts" {
  family = "ubuntu-2404-lts-oslogin"
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

### Server vm-yc-web01 

resource "yandex_compute_instance" "web01" {

  name        ="vm-yc-web01"
  hostname    ="vm-yc-web01"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    memory        = var.websrv.memory
    cores         = var.websrv.cores
    core_fraction = var.websrv.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.websrv.drive_size
    }
  }

  network_interface {
    subnet_id          = "${yandex_vpc_subnet.subnet-private-web1.id}"
    ip_address         = "10.0.1.20"
    security_group_ids = [yandex_vpc_security_group.private-sg.id]
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    nginx-config       = file("boostrap/nginx.yaml")
  }
}


### Server vm-yc-web02

resource "yandex_compute_instance" "web02" {

  name        ="vm-yc-web02"
  hostname    ="vm-yc-web02"
  zone        = "ru-central1-b"
  platform_id = "standard-v3"

  resources {
    memory        = var.websrv.memory
    cores         = var.websrv.cores
    core_fraction = var.websrv.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.websrv.drive_size
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-private-web2.id}"
    ip_address         = "10.0.2.20"
    security_group_ids = [yandex_vpc_security_group.private-sg.id]
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    nginx-config       = file("boostrap/nginx.yaml")
  }
}

### Настройка Target Group web01 and web02

resource "yandex_alb_target_group" "tg-web" {
  name = "tg-web"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-private-web1.id}"
    ip_address = "${yandex_compute_instance.web01.network_interface.0.ip_address}"
  }
  target {
    subnet_id = "${yandex_vpc_subnet.subnet-private-web2.id}"
    ip_address = "${yandex_compute_instance.web02.network_interface.0.ip_address}"
  }
}

### Настройка Backend group, healthcheck http 80 

resource "yandex_alb_backend_group" "backend-group-web" {
  name                     = "backend-group-web"

  http_backend {
    name                   = "bg-web"
    weight                 = 1  
    port                   = 80
    target_group_ids       = [yandex_alb_target_group.tg-web.id]
    load_balancing_config {
      panic_threshold      = 90
    }    
    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15 
      http_healthcheck {
        path               = "/"
      }
    }
  }
}

### Настройка HTTP-Router 

resource "yandex_alb_http_router" "router-http" {
  name = "router-http"
}

resource "yandex_alb_virtual_host" "router-web" {
  name           = "router-web"
  http_router_id = yandex_alb_http_router.router-http.id
  route {
    name = "route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.backend-group-web.id
        timeout          = "3s"
      }
    }
  }
}

### Настройка Application load balancer

resource "yandex_alb_load_balancer" "alb-web" {
  name        = "alb-web"
  network_id  = "${yandex_vpc_network.network-1.id}"
  security_group_ids = [yandex_vpc_security_group.load-balancer-sg.id, yandex_vpc_security_group.private-sg.id] 
  
  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = "${yandex_vpc_subnet.subnet-public1.id}"
    }
  }

  listener {
    name = "listener-web"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = yandex_alb_http_router.router-http.id
      }
    }
  }
}

### Server Zabbix vm-yc-zbx01 

resource "yandex_compute_instance" "zabbix" {

  name        = "vm-yc-zbx01"
  hostname    = "vm-yc-zbx01"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    memory        = var.zabbix.memory
    cores         = var.zabbix.cores
    core_fraction = var.zabbix.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.zabbix.drive_size
    }
  }

  network_interface {
    subnet_id          = "${yandex_vpc_subnet.subnet-public1.id}"
    ip_address         = "10.1.1.20"    
    nat                = true
    security_group_ids = ["${yandex_vpc_security_group.private-sg.id}"]
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
  }
}

### Server Elasticsearch vm-yc-elk01

resource "yandex_compute_instance" "elk" {

  name        ="vm-yc-elk01"
  hostname    ="vm-yc-elk01"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    memory        = var.elk.memory
    cores         = var.elk.cores
    core_fraction = var.elk.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.elk.drive_size
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-private-elk.id}"
    security_group_ids = [yandex_vpc_security_group.private-sg.id, yandex_vpc_security_group.elasticsearch-sg.id]
    ip_address = "10.0.3.20"
  }
  metadata = {
    user-data          = file("./cloud-init.yml")
  }
}  

### Server Kibana vm-yc-kib01

resource "yandex_compute_instance" "kib" {

  name        ="vm-yc-kib01"
  hostname    ="vm-yc-kib01"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    memory        = var.kib.memory
    cores         = var.kib.cores
    core_fraction = var.kib.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.kib.drive_size
    }
  }

  network_interface {
    subnet_id          = "${yandex_vpc_subnet.subnet-public1.id}"
    ip_address         = "10.1.1.30"  
    nat                = true
    security_group_ids =  [yandex_vpc_security_group.private-sg.id, yandex_vpc_security_group.kibana-sg.id]
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
  }
}

### Server Bastion vm-yc-bst01

resource "yandex_compute_instance" "bastion" {

  name        ="vm-yc-bst01"
  hostname    ="vm-yc-bst01"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"

  resources {
    memory        = var.bastion.memory
    cores         = var.bastion.cores
    core_fraction = var.bastion.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      type     = "network-hdd"
      size     = var.bastion.drive_size
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-public1.id}"
    security_group_ids =[yandex_vpc_security_group.bastion-sg.id]
    nat = true
}

  metadata = {
    user-data          = file("./cloud-init.yml")
  }
}