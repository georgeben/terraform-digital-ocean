terraform {
  required_providers{
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.3.0"
    }
  }
}

variable do_token {}
variable private_key {}

variable region {
  type = string
  default = "fra1"
}
variable size {
  type = string
  default = "s-1vcpu-1gb"
}
variable droplet_count {
  type = number
  default = 2
}
variable droplet_name {
  type = string
  default = "www"
}
variable droplet_image {
  type = string
  default = "ubuntu-18-04-x64"
}

provider "digitalocean" {
  token = var.do_token
}


data "digitalocean_ssh_key" "terraform" {
  name = "terraform"
}

resource "digitalocean_droplet" "web" {
  count = var.droplet_count
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
    timeout = "3m"
  }
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      #install NGINX
      "sudo apt-get update",
      "sudo apt-get -y install nginx",
      "echo '<h3>web-${var.region}-${count.index + 1}</h3>' >> /var/www/html/index.nginx-debian.html"
    ]
  }
  lifecycle {
    # Prevents outages
    create_before_destroy = true
  }
}

output "server_ip" {
  value = digitalocean_droplet.web.*.ipv4_address
}

resource "digitalocean_loadbalancer" "www_lb" {
  name = "www-lb-${var.region}"
  region = var.region

  forwarding_rule {
    entry_port = 80
    entry_protocol = "http"

    target_port = 80
    target_protocol = "http"
  }

  healthcheck {
    port = 22
    protocol = "tcp"
  }

  droplet_ids = digitalocean_droplet.web.*.id
}

output "lb_ip" {
  value = digitalocean_loadbalancer.www_lb.ip
}
