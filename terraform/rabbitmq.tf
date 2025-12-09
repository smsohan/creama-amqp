data "google_secret_manager_secret_version" "rabbitmq_password" {
  secret  = google_secret_manager_secret.rabbitmq_password_secret.secret_id
  version = "latest"
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
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -e
    sudo apt-get update
    sudo apt-get install -y erlang rabbitmq-server

    sudo rabbitmq-plugins enable rabbitmq_management

    sudo rabbitmqctl add_user ${var.rabbitmq_user} ${data.google_secret_manager_secret_version.rabbitmq_password.secret_data}
    sudo rabbitmqctl set_user_tags ${var.rabbitmq_user} administrator
    sudo rabbitmqctl set_permissions -p / ${var.rabbitmq_user} ".*" ".*" ".*"

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
