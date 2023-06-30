# proj-6-terraform-infra

## Description

This repository contains the Terraform infrastructure code for the [Distributed Image Processing Application](https://github.com/jordanholtdev/proj-6-frontend) . It provisions and manages the required resources on AWS to support the project's infrastructure.

## Getting Started

These instructions will help you get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

-   [Terraform](https://www.terraform.io/downloads.html) installed locally
-   A Terraform Cloud account ([Sign up here](https://app.terraform.io/signup/account))
-   [AWS Account](https://aws.amazon.com/) and credentials set up

### Installation

1. Clone this repository: `git clone https://github.com/jordanholtdev/proj-6-terraform-infra.git`
2. Change into the project directory: `cd proj-6-terraform-infra`
3. Sign in to Terraform Cloud using the command: `terraform login`
4. Initialize Terraform: `terraform init`
5. Modify the `variables.tf` file to configure the desired infrastructure settings.
6. Commit and push your changes to the repository.

## Terraform Cloud Configuration

To configure Terraform Cloud for this project, follow these steps:

1. Log in to [Terraform Cloud](https://app.terraform.io) using your Terraform Cloud account.
2. Create a new workspace for this project.
3. Connect the workspace to this repository.
4. Set up the required variables in the workspace, such as API keys, credentials, or any environment-specific configuration.

## Usage

To provision and manage the infrastructure using Terraform Cloud:

1. Make changes to the Terraform code as needed.
2. Commit and push your changes to the repository.
3. Terraform Cloud will automatically detect the changes and trigger a run.
4. Monitor the run status and logs through the Terraform Cloud UI.
5. If necessary, update the variables or make configuration changes in the Terraform Cloud workspace.
