# Terraform Setup for RabbitMQ on GCE with Cloud Run Producer/Consumer

This directory contains the Terraform code to deploy the entire infrastructure as described in the main [README.md](../README.md).

## Prerequisites

1.  **Google Cloud SDK:** Make sure you have the `gcloud` CLI installed and authenticated.
2.  **Terraform:** Install Terraform CLI.
3.  **Project:** You need a GCP project with billing enabled.
4.  **APIs:** Enable the following APIs in your GCP project:
    *   Compute Engine API
    *   Cloud Run Admin API
    *   Secret Manager API
    *   VPC Access API
5.  **Container Images:** Build and push the producer and consumer application container images to Google Container Registry (GCR). Make sure to update the image paths in `cloudrun.tf` accordingly.

## How to Use

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```

2.  **Create a `terraform.tfvars` file:**
    Create a file named `terraform.tfvars` and add the following, replacing `<YOUR_PROJECT_ID>` with your GCP project ID:
    ```tfvars
    project_id = "<YOUR_PROJECT_ID>"
    ```
    You can also override other variables defined in `variables.tf` in this file.

3.  **Plan the deployment:**
    ```bash
    terraform plan --var-file=<.tfvars>
    ```
    Review the plan to see what resources will be created.

4.  **Apply the changes:**
    ```bash
    terraform apply --var-file=<.tfvars>
    ```
    This will deploy all the resources. It might take a few minutes to complete.

5.  **Accessing the services:**
    *   **Producer:** The URL of the producer service will be in the Terraform output `producer_url`.
    *   **RabbitMQ Management UI:** The URL for the management UI is in the `rabbitmq_management_ui_url` output. The username is `user` (or what you configured) and the password can be retrieved from Secret Manager using the secret ID from the `rabbitmq_password_secret_id` output.

6.  **Cleaning up:**
    To destroy all the resources created by this Terraform code, run:
    ```bash
    terraform destroy
    ```
    This will delete all the resources, including the GCE VM, Cloud Run services, and the secret.
