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
    description    = "WebApp 8090"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8090
  }

  ingress {
    protocol       = "TCP"
    description    = "ClickHouse"
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

# Managed MySQL Cluster
resource "yandex_mdb_mysql_cluster" "dev_db" {
  name        = "dev-db"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.default.id
  version     = "8.0"

  resources {
    resource_preset_id = var.db_resources.preset_id
    disk_type_id       = "network-hdd"
    disk_size          = var.db_resources.disk_size
  }

  host {
    zone      = var.zone
    subnet_id = yandex_vpc_subnet.default.id
    name      = "db-host"
  }
}

resource "yandex_mdb_mysql_database" "dev_db" {
  cluster_id = yandex_mdb_mysql_cluster.dev_db.id
  name       = var.db_name
}

resource "yandex_mdb_mysql_user" "dev_user" {
  cluster_id = yandex_mdb_mysql_cluster.dev_db.id
  name       = var.db_user
  password   = var.db_password
  
  permission {
    database_name = yandex_mdb_mysql_database.dev_db.name
    roles         = ["ALL"]
  }
}

# Data source для получения образа Rocky Linux 9 с OS Login по ID
data "yandex_compute_image" "rocky_oslogin" {
  image_id = "fd8g26jck6v78uiovdch"
}

# Хост для ClickHouse
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
      image_id = data.yandex_compute_image.rocky_oslogin.id
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

# Хост для Vector
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
      image_id = data.yandex_compute_image.rocky_oslogin.id
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

# Хост для Lighthouse
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
      image_id = data.yandex_compute_image.rocky_oslogin.id
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
  description = "External IP address of ClickHouse VM"
}

output "vector_external_ip" {
  value       = yandex_compute_instance.vector.network_interface.0.nat_ip_address
  description = "External IP address of Vector VM"
}

output "lighthouse_external_ip" {
  value       = yandex_compute_instance.lighthouse.network_interface.0.nat_ip_address
  description = "External IP address of Lighthouse VM"
}

output "mysql_cluster_ip" {
  value       = yandex_mdb_mysql_cluster.dev_db.host.0.fqdn
  description = "MySQL cluster host FQDN"
}
