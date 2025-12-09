# output "producer_url" {
#   description = "The URL of the producer Cloud Run service."
#   value       = google_cloud_run_v2_service.producer.uri
# }

output "rabbitmq_management_ui_url" {
  description = "The URL of the RabbitMQ management UI."
  value       = "http://${google_compute_instance.rabbitmq_vm.network_interface[0].network_ip}:15672"
}

output "rabbitmq_password_secret_id" {
  description = "The ID of the secret containing the RabbitMQ password."
  value       = google_secret_manager_secret.rabbitmq_password_secret.secret_id
}
