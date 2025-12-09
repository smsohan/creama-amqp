#!/bin/bash
set -e

# Variables
export PROJECT_ID=$(gcloud config get-value project)
export REGION=${REGION:-us-central1}
REPO_NAME="crema-amqp"
PRODUCER_IMAGE_NAME="producer"
CONSUMER_IMAGE_NAME="consumer"
DOCKERFILE_PRODUCER_PATH="producer"
DOCKERFILE_CONSUMER_PATH="consumer"

# 1. Create Artifact Registry repository
echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create "$REPO_NAME" \
  --repository-format=docker \
  --location="$REGION" \
  --description="Docker repository for crema-amqp" || echo "Repository $REPO_NAME already exists."

# 2. Build and push producer image
echo "Building and pushing producer image..."
PRODUCER_IMAGE_URL="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$PRODUCER_IMAGE_NAME"
docker build -t "$PRODUCER_IMAGE_URL" "$DOCKERFILE_PRODUCER_PATH"
docker push "$PRODUCER_IMAGE_URL"

# 3. Build and push consumer image
echo "Building and pushing consumer image..."
CONSUMER_IMAGE_URL="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$CONSUMER_IMAGE_NAME"
docker build -t "$CONSUMER_IMAGE_URL" "$DOCKERFILE_CONSUMER_PATH"
docker push "$CONSUMER_IMAGE_URL"

# 4. Get image digests
echo "Getting image digests..."
PRODUCER_IMAGE_DIGEST=$(gcloud artifacts docker images describe "${PRODUCER_IMAGE_URL}:latest" --format='get(image_summary.fully_qualified_digest)')
CONSUMER_IMAGE_DIGEST=$(gcloud artifacts docker images describe "${CONSUMER_IMAGE_URL}:latest" --format='get(image_summary.fully_qualified_digest)')

echo "Producer image digest: $PRODUCER_IMAGE_DIGEST"
echo "Consumer image digest: $CONSUMER_IMAGE_DIGEST"

# 5. Run Terraform
echo "Running Terraform..."
cd terraform
terraform init
terraform apply -auto-approve \
  -var="project_id=$PROJECT_ID" \
  -var="region=$REGION" \
  -var="producer_image=$PRODUCER_IMAGE_DIGEST" \
  -var="consumer_image=$CONSUMER_IMAGE_DIGEST"
