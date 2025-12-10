resource "google_service_account" "crema_sa" {
    account_id   = "crema-sa"
    display_name = "Service Account for Crema AMQP"
}

resource "google_project_iam_binding" "crema_parameter_viewer_binding" {
    project = var.project_id
    role    = "roles/parametermanager.parameterViewer"
    members  = ["serviceAccount:${google_service_account.crema_sa.email}"]
}

resource "google_service_account_iam_member" "crema_sa_run_sa_binding" {
  service_account_id = google_service_account.run_sa.id
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.crema_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "crema_secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.rabbitmq_management_password_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.crema_sa.email}"
}

resource "google_cloud_run_v2_worker_pool_iam_binding" "crema_worker_pool_developer_role" {
    location = var.region
    name  = google_cloud_run_v2_worker_pool.consumer.name
    role     = "roles/run.developer"
    members  = ["serviceAccount:${google_service_account.crema_sa.email}"]
}

resource "google_parameter_manager_parameter" "crema-rabbitmq-parameter" {
    parameter_id = "crema-rabbitmq-parameter"
    format = "YAML"
}

resource "google_parameter_manager_parameter_version" "crema-rabbitmq-parameter-version" {
  parameter = google_parameter_manager_parameter.crema-rabbitmq-parameter.id
  parameter_version_id = "crema_rabbitmq_parameter_version2"
  parameter_data = templatefile("${path.module}/crema-rabbitmq.yml", {
    host = google_compute_instance.rabbitmq_vm.network_interface[0].network_ip,
    queue = var.rabbitmq_queue,
    project_id = var.project_id,
    region = var.region,
    worker_pool_name = google_cloud_run_v2_worker_pool.consumer.name,
    user = var.rabbitmq_management_user,
    password = google_secret_manager_secret_version.rabbitmq_management_password_secret_version.secret_data
  })
}



resource "google_cloud_run_v2_service" "crema-rabbitmq-scaler" {
  name     = "crema-rabbitmq-scaler"
  location = var.region
  deletion_protection=false
  depends_on = [ google_project_iam_binding.crema_parameter_viewer_binding ]

    scaling {
        manual_instance_count = 1
        scaling_mode = "MANUAL"
    }


  template {
    service_account = google_service_account.crema_sa.email

    containers {
      image = var.scaler_image
      base_image_uri = "us-central1-docker.pkg.dev/serverless-runtimes/google-22/runtimes/java21"

      env {
        name = "CREMA_CONFIG"
        value = google_parameter_manager_parameter_version.crema-rabbitmq-parameter-version.id
      }

      env {
        name = "OUTPUT_SCALER_METRICS"
        value = "True"
      }

      resources {
        cpu_idle = false
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