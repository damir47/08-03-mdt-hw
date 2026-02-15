### Route table 

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_table" {
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

### Subnet private  vm-yc-web01

resource "yandex_vpc_subnet" "subnet-private-web1" {
  name           = "subnet-private-web1"
  description    = "subnet for vm-yc-web01"
  zone           = "ru-central1-a" 
  network_id     = "${yandex_vpc_network.network-1.id}"
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

### Subnet private vm-yc-web02

resource "yandex_vpc_subnet" "subnet-private-web2" {
  name           = "subnet-private-web2"
  description    = "subnet for vm-yc-web02"
  zone           = "ru-central1-b" 
  network_id     = "${yandex_vpc_network.network-1.id}"
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}

### Subnet private vm-yc-elk

resource "yandex_vpc_subnet" "subnet-private-elk" {
  name           = "subnet-private-elk"
  description    = "subnet for vm-yc-elk"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.network-1.id}"
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}

### Subnet public for DMZ


resource "yandex_vpc_subnet" "subnet-public1" {
  name           = "subnet-public1"
  description    = "subnet for services"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["10.1.1.0/24"]
}