variable "project_id" {
  description = "The GCP project ID to deploy the resources in."
  type        = string
}

variable "region" {
  description = "The GCP region to deploy the resources in."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to deploy the GCE VM in."
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "The name of the GCE instance."
  type        = string
  default     = "rabbitmq-vm"
}

variable "instance_type" {
  description = "The machine type for the GCE instance."
  type        = string
  default     = "e2-medium"
}

variable "network_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "rabbitmq-network"
}

variable "subnet_name" {
  description = "The name of the VPC subnetwork."
  type        = string
  default     = "rabbitmq-subnet"
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnetwork."
  type        = string
  default     = "10.10.10.0/24"
}

variable "rabbitmq_user" {
  description = "The username for RabbitMQ."
  type        = string
  default     = "user"
}

variable "rabbitmq_queue" {
  description = "The name of the RabbitMQ queue."
  type        = string
  default     = "my-queue"
}

variable "rabbitmq_topic" {
  description = "The name of the RabbitMQ topic (exchange)."
  type        = string
  default     = "my-topic"
}

variable "producer_image" {
  description = "The container image for the producer service."
  type        = string
}

variable "consumer_image" {
  description = "The container image for the consumer service."
  type        = string
}