resource "random_password" "rabbitmq_password" {
  length  = 16
  special = false
}

resource "google_secret_manager_secret" "rabbitmq_password_secret" {
  secret_id = "rabbitmq-password"

  replication {
    auto {

    }
  }
}

resource "google_secret_manager_secret_version" "rabbitmq_password_secret_version" {
  secret      = google_secret_manager_secret.rabbitmq_password_secret.id
  secret_data = random_password.rabbitmq_password.result
}

resource "random_password" "rabbitmq_management_password" {
  length  = 16
  special = false
}

resource "google_secret_manager_secret" "rabbitmq_management_password_secret" {
  secret_id = "rabbitmq-management-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "rabbitmq_management_password_secret_version" {
  secret      = google_secret_manager_secret.rabbitmq_management_password_secret.id
  secret_data = random_password.rabbitmq_management_password.result
}
