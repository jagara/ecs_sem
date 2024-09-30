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

Before using this repository, ensure you have the following tools installed and properly configured:

- [Docker](https://www.docker.com/): To build and run the application containers.
- [Terraform](https://www.terraform.io/): To manage the infrastructure provisioning.
- [AWS CLI](https://aws.amazon.com/cli/): Required for deploying the infrastructure to AWS.
- An AWS account with appropriate permissions for ECS and Terraform.

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ecs_sem
```
### 2. Configure Terraform Variables

The variables.tf file contains several variables you can customize before deploying, such as:
    - aws_region: The AWS region to deploy the infrastructure.
    - email_addresses: Email address from wich will be send emails.
### 3. Deploy with Terraform

Initialize and apply the Terraform configuration to provision the infrastructure:

```bash
terraform init
terraform apply
```
Terraform will create the following resources:

    - ECS Cluster to run the containers.
    - ECS Services for Redis and email microservice.
    - Networking components (VPC, subnets, etc.).
    - Task definitions for each service.
### 4. Access the Services
After the infrastructure is deployed, Terraform will output the URLs or endpoints for the services. You can view these in the Terraform output (managed via output.tf).

 - append /api to output **``load_balancer_dns_name``** to access api 

 ### 5. Tearing Down

When you're done with the infrastructure, you can clean it up by running:

```bash
terraform destroy
```
This will remove all resources created by Terraform.
