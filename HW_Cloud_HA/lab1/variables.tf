variable "yc_token" {}

variable "flow" {
  type    = string
  default = "damir"
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

variable "websrv" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 1
    core_fraction = 20
    drive_size    = 10
  }
}

