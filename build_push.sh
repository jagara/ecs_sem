#!/bin/bash

set -e

IMAGE_NAME=$1
REPOSITORY_URL=$2
IMAGE_TAG=$3
AWS_REGION=$4
AWS_ACCOUNT_ID=$5

# Authenticate Docker to the ECR registry
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPOSITORY_URL

# Build the Docker image
docker build -t $IMAGE_NAME -f Dockerfile.$IMAGE_NAME .

# Tag the Docker image
docker tag $IMAGE_NAME:latest $REPOSITORY_URL:$IMAGE_TAG

# Push the Docker image to ECR
docker push $REPOSITORY_URL:$IMAGE_TAG
