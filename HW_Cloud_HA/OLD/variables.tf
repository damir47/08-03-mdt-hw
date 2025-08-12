variable "yc_token" {}

variable "flow" {
  type    = string
  default = "24-47"
}

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

variable "test" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
}

variable "db" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
}

