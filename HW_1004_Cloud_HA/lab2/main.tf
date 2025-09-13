data "yandex_compute_image" "ubuntu_2404_lts" {
  family = "ubuntu-2404-lts-oslogin"
}

resource "yandex_iam_service_account" "ig-sa" {
  name        = "ig-sa"
  description = "Сервисный аккаунт для управления группой ВМ."
}

resource "yandex_resourcemanager_folder_iam_member" "compute-editor" {
  folder_id = var.folder_id
  role      = "compute.editor"
  member    = "serviceAccount:${yandex_iam_service_account.ig-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "load-balancer-editor" {
  folder_id = var.folder_id
  role      = "load-balancer.editor"
  member    = "serviceAccount:${yandex_iam_service_account.ig-sa.id}"
}

resource "yandex_compute_instance_group" "ig-1" {
  name                = "fixed-ig-with-balancer"
  folder_id           = var.folder_id
  service_account_id  = "${yandex_iam_service_account.ig-sa.id}"
  deletion_protection = "false"
  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = var.websrv.memory
      cores  = var.websrv.cores
      core_fraction = var.websrv.core_fraction
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
      }
    }

    network_interface {
      network_id         = "${yandex_vpc_network.network-1.id}"
      subnet_ids         = ["${yandex_vpc_subnet.subnet-1.id}"]
#      security_group_ids = ["<список_идентификаторов_групп_безопасности>"]
    }

    metadata = {
      user-data          = file("./cloud-init.yml")
      user-data          = file("./nginx-install.yaml")
      serial-port-enable = 1
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 10
    max_expansion   = 0
  }

  load_balancer {
    target_group_name        = "target-group"
    target_group_description = "Целевая группа Network Load Balancer"
  }
}

resource "yandex_lb_network_load_balancer" "lb-1" {
  name = "network-load-balancer-1"

  listener {
    name = "network-load-balancer-1-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.ig-1.load_balancer.0.target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/index.html"
      }
    }
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["10.32.1.0/24"]
}