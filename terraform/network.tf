resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc_network.id
  region        = var.region
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_rabbitmq" {
  name    = "${var.network_name}-allow-rabbitmq"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["5672", "15672"] # Default RabbitMQ ports
  }
  source_ranges = [var.subnet_cidr]
}

# resource "google_vpc_access_connector" "connector" {
#   name          = "vpc-connector"
#   ip_cidr_range = "10.8.0.0/28"
#   network       = google_compute_network.vpc_network.name
#   region        = var.region
# }
