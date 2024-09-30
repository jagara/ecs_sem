# ECS SEM App

## Overview

This repository contains the configuration files and scripts to deploy a Redis service and an email-sending microservice using Docker containers managed by **AWS ECS** (Elastic Container Service). The infrastructure is provisioned using **Terraform**, allowing for scalable and automated cloud deployment.

## Repository Structure

- **`build_push.sh`**: Script for building and pushing Docker images to a container registry (e.g., AWS ECR).
- **`Dockerfile.send-any-email`**: Dockerfile for building an email-sending microservice container.
- **`main.tf`**: Main Terraform configuration file for AWS ECS infrastructure setup.
- **`output.tf`**: Outputs important infrastructure information such as ECS cluster and service URLs.
- **`variables.tf`**: Defines the input variables used in Terraform, allowing customization of various infrastructure parameters (e.g., instance types, service names, etc.).

## Prerequisites

Before using this reposito