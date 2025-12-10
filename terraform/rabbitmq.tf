data "google_secret_manager_secret_version" "rabbitmq_password" {
  secret  = google_secret_manager_secret.rabbitmq_password_secret.secret_id
  version = "latest"
}

data "google_secret_manager_secret_version" "rabbitmq_management_password" {
  secret  = google_secret_manager_secret.rabbitmq_management_password_secret.secret_id
  version = "latest"
  depends_on = [ google_secret_manager_secret_version.rabbitmq_password_secret_version ]
}

resource "google_compute_address" "static" {
  name = "ipv4-address"
}

resource "google_compute_instance" "rabbitmq_vm" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc_subnetwork.id
    network_ip = "10.10.10.10"
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    sudo apt-get update
    sudo apt-get install -y erlang rabbitmq-server

    sudo rabbitmq-plugins enable rabbitmq_management

    # Create regular user
    sudo rabbitmqctl add_user ${var.rabbitmq_user} ${data.google_secret_manager_secret_version.rabbitmq_password.secret_data}
    sudo rabbitmqctl set_user_tags ${var.rabbitmq_user} administrator
    sudo rabbitmqctl set_permissions -p / ${var.rabbitmq_user} ".*" ".*" ".*"

    # Create management user
    sudo rabbitmqctl add_user ${var.rabbitmq_management_user} ${data.google_secret_manager_secret_version.rabbitmq_management_password.secret_data}
    sudo rabbitmqctl set_user_tags ${var.rabbitmq_management_user} management
    sudo rabbitmqctl set_permissions -p / ${var.rabbitmq_management_user} ".*" ".*" ".*"

    # Declare queue
    sudo rabbitmqadmin -u ${var.rabbitmq_user} -p ${data.google_secret_manager_secret_version.rabbitmq_password.secret_data} declare queue name=${var.rabbitmq_queue} durable=true

    # Declare exchange (topic)
    sudo rabbitmqadmin -u ${var.rabbitmq_user} -p ${data.google_secret_manager_secret_version.rabbitmq_password.secret_data} declare exchange name=${var.rabbitmq_topic} type=topic durable=true

    # Bind queue to exchange
    sudo rabbitmqadmin -u ${var.rabbitmq_user} -p ${data.google_secret_manager_secret_version.rabbitmq_password.secret_data} declare binding source="${var.rabbitmq_topic}" destination_type="queue" destination="${var.rabbitmq_queue}" routing_key="#"

    sudo systemctl restart rabbitmq-server
  EOT

  tags = ["rabbitmq-server"]

  service_account {
    scopes = ["cloud-platform"]
  }
}
