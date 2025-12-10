# IAM binding for Cloud Run service account to access the secret
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  project   = google_secret_manager_secret.rabbitmq_password_secret.project
  secret_id = google_secret_manager_secret.rabbitmq_password_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run_sa.email}"
}

# Enables the Cloud Run API
resource "google_project_service_identity" "run_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "run.googleapis.com"
}

resource "google_service_account" "run_sa" {
    account_id   = "run-rabbitmq-sa"
    display_name = "Service Account for AMQP producers consumers"
}

resource "google_cloud_run_v2_service" "producer" {
  name     = "producer-service"
  location = var.region
  deletion_protection = false

  template {
    service_account = google_service_account.run_sa.email
    containers {
      image = var.producer_image
      ports {
        container_port = 8080
      }
      env {
        name  = "RABBITMQ_HOST"
        value = google_compute_instance.rabbitmq_vm.network_interface[0].network_ip
      }
      env {
        name  = "RABBITMQ_PORT"
        value = "5672"
      }
      env {
        name  = "RABBITMQ_USER"
        value = var.rabbitmq_user
      }
      env {
        name = "RABBITMQ_PASSWORD"
        value_source {
          secret_key_ref {
            secret = google_secret_manager_secret.rabbitmq_password_secret.secret_id
            version = google_secret_manager_secret_version.rabbitmq_password_secret_version.version
          }
        }
      }
      env {
        name  = "RABBITMQ_QUEUE"
        value = var.rabbitmq_queue
      }
    }

    vpc_access{
      network_interfaces {
        network = google_compute_network.vpc_network.name
        subnetwork = google_compute_subnetwork.vpc_subnetwork.name
      }
    }

  }
}

resource "google_cloud_run_v2_worker_pool" "consumer" {
  name     = "consumer-worker"
  location = var.region
  launch_stage = "BETA"
  deletion_protection = false

  scaling {
    manual_instance_count = 1
  }

  template {
    service_account = google_service_account.run_sa.email
    containers {
      image = var.consumer_image
      env {
        name  = "RABBITMQ_HOST"
        value = google_compute_instance.rabbitmq_vm.network_interface[0].network_ip
      }
      env {
        name  = "RABBITMQ_PORT"
        value = "5672"
      }
      env {
        name  = "RABBITMQ_USER"
        value = var.rabbitmq_user
      }
      env {
        name = "RABBITMQ_PASSWORD"
        value_source {
          secret_key_ref {
            secret = google_secret_manager_secret.rabbitmq_password_secret.secret_id
            version = google_secret_manager_secret_version.rabbitmq_password_secret_version.version
          }
        }
      }
      env {
        name  = "RABBITMQ_QUEUE"
        value = var.rabbitmq_queue
      }

      env {
        name = "QPS"
        value = "1"
      }
    }

    vpc_access{
      network_interfaces {
        network = google_compute_network.vpc_network.name
        subnetwork = google_compute_subnetwork.vpc_subnetwork.name
      }
    }
  }
}
