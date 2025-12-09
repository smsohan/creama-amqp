# # IAM binding for Cloud Run service account to access the secret
# resource "google_secret_manager_secret_iam_member" "secret_accessor" {
#   project   = var.project_id
#   secret_id = google_secret_manager_secret.rabbitmq_password_secret.id
#   role      = "roles/secretmanager.secretAccessor"
#   member    = "serviceAccount:${google_project_service_identity.run_sa.email}"
# }

# # Enables the Cloud Run API
# resource "google_project_service_identity" "run_sa" {
#   provider = google-beta
#   project  = var.project_id
#   service  = "run.googleapis.com"
# }


# resource "google_cloud_run_v2_service" "producer" {
#   name     = "producer-service"
#   location = var.region

#   template {
#     containers {
#       image = "gcr.io/${var.project_id}/producer:latest" # Replace with your producer image
#       ports {
#         container_port = 8080
#       }
#       env {
#         name  = "RABBITMQ_HOST"
#         value = google_compute_instance.rabbitmq_vm.network_interface[0].network_ip
#       }
#       env {
#         name  = "RABBITMQ_PORT"
#         value = "5672"
#       }
#       env {
#         name  = "RABBITMQ_USER"
#         value = var.rabbitmq_user
#       }
#       env {
#         name = "RABBITMQ_PASSWORD_SECRET_NAME"
#         value = google_secret_manager_secret.rabbitmq_password_secret.secret_id
#       }
#       env {
#         name  = "RABBITMQ_QUEUE"
#         value = var.rabbitmq_queue
#       }
#     }
#     vpc_access {
#       connector = google_vpc_access_connector.connector.id
#       egress    = "ALL_TRAFFIC"
#     }
#   }
# }

# resource "google_cloud_run_v2_service" "consumer" {
#   name     = "consumer-worker"
#   location = var.region
#   launch_stage = "BETA"

#   template {
#     scaling {
#       min_instance_count = 1
#       max_instance_count = 10
#     }
#     containers {
#       image = "gcr.io/${var.project_id}/consumer:latest" # Replace with your consumer image
#       env {
#         name  = "RABBITMQ_HOST"
#         value = google_compute_instance.rabbitmq_vm.network_interface[0].network_ip
#       }
#       env {
#         name  = "RABBITMQ_PORT"
#         value = "5672"
#       }
#       env {
#         name  = "RABBITMQ_USER"
#         value = var.rabbitmq_user
#       }
#       env {
#         name = "RABBITMQ_PASSWORD_SECRET_NAME"
#         value = google_secret_manager_secret.rabbitmq_password_secret.secret_id
#       }
#       env {
#         name  = "RABBITMQ_TOPIC"
#         value = var.rabbitmq_topic
#       }
#       env {
#         name = "QPS"
#         value = "10"
#       }
#     }
#     vpc_access {
#       connector = google_vpc_access_connector.connector.id
#       egress    = "ALL_TRAFFIC"
#     }
#   }
# }
