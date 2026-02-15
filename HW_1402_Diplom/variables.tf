variable "yc_token" {}

# cloud-miniahmetov-dt
variable "cloud_id" {
  type    = string
  default = "b1ga68093lonh4ujkp7k"
}
# netology-labs-mdt
variable "folder_id" {
  type    = string
  default = "b1gp28psolf4bfbeo1sm"
}

variable "websrv" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 2
    core_fraction = 20
    drive_size    = 10
  }
}

variable "zabbix" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 2
    core_fraction = 20
    drive_size    = 20
  }
}

variable "elk" {
  type = map(number)
  default = {
    cores         = 4
    memory        = 8
    core_fraction = 20
    drive_size    = 30
  }
}

variable "kib" {
  type = map(number)
  default = {
    cores         = 4
    memory        = 8
    core_fraction = 20
    drive_size    = 30
  }
}

variable "bastion" {
  type = map(number)
  default = {
    cores         = 4
    memory        = 8
    core_fraction = 20
    drive_size    = 30
  }
}