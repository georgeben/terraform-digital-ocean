terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.3.0"
    }
  }
}

variable "do_token" {}
variable "private_key" {}

variable "region" {
  type    = string
  default = "fra1"
}
variable "size" {
  type    = string
  default = "s-1vcpu-1gb"
}
variable "droplet_count" {
  type    = number
  default = 1
}
variable "droplet_name" {
  type    = string
  default = "www"
}
variable "droplet_image" {
  type    = string
  default = "ubuntu-18-04-x64"
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_account" "account_info" {}

# Display Digital ocean account information
output "account_info" {
  value = data.digitalocean_account.account_info
}

data "digitalocean_ssh_key" "terraform" {
  name = "terraform"
}

resource "digitalocean_droplet" "web" {
  count  = var.droplet_count
  image  = var.droplet_image
  name   = "${var.droplet_name}-${var.region}-${count.index + 1}"
  region = var.region
  size   = var.size
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.private_key)
    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update",
      "sudo apt-get -y install nginx"
    ]
  }
}

output "server_ip" {
  value = digitalocean_droplet.web.*.ipv4_address
}
