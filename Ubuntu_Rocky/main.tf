# Network
resource "yandex_vpc_network" "default" {
  name = "dev-network"
}

resource "yandex_vpc_subnet" "default" {
  name           = "dev-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Security Group
resource "yandex_vpc_security_group" "devoll" {
  name        = "dev-oll"
  description = "Security group for web application"
  network_id  = yandex_vpc_network.default.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "ClickHouse HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8123
  }

  ingress {
    protocol       = "TCP"
    description    = "Vector API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8686
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Data source для Rocky Linux 9
data "yandex_compute_image" "rocky" {
  family = "rocky-linux-9"
}

# Data source для Ubuntu 22.04 LTS
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# Хост для ClickHouse (Ubuntu)
resource "yandex_compute_instance" "clickhouse" {
  name        = "clickhouse"
  platform_id = "standard-v2"
  zone        = var.zone

  resources {
    cores  = var.vm_resources.cores
    memory = var.vm_resources.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.vm_resources.disk
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.default.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.devoll.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
  }
}

# Хост для Vector (Rocky Linux)
resource "yandex_compute_instance" "vector" {
  name        = "vector"
  platform_id = "standard-v2"
  zone        = var.zone

  resources {
    cores  = var.vm_resources.cores
    memory = var.vm_resources.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.rocky.id
      size     = var.vm_resources.disk
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.default.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.devoll.id]
  }

  metadata = {
    ssh-keys = "rocky:${file(var.ssh_public_key)}"
  }
}

# Хост для Lighthouse (Rocky Linux)
resource "yandex_compute_instance" "lighthouse" {
  name        = "lighthouse"
  platform_id = "standard-v2"
  zone        = var.zone

  resources {
    cores  = var.vm_resources.cores
    memory = var.vm_resources.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.rocky.id
      size     = var.vm_resources.disk
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.default.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.devoll.id]
  }

  metadata = {
    ssh-keys = "rocky:${file(var.ssh_public_key)}"
  }
}

# Outputs
output "clickhouse_external_ip" {
  value       = yandex_compute_instance.clickhouse.network_interface.0.nat_ip_address
  description = "External IP address of ClickHouse VM (Ubuntu)"
}

output "vector_external_ip" {
  value       = yandex_compute_instance.vector.network_interface.0.nat_ip_address
  description = "External IP address of Vector VM (Rocky Linux)"
}

output "lighthouse_external_ip" {
  value       = yandex_compute_instance.lighthouse.network_interface.0.nat_ip_address
  description = "External IP address of Lighthouse VM (Rocky Linux)"
}