# Cloud Resume

A serverless resume and portfolio site built on AWS as an implementation
of the Cloud Resume Challenge.

## Architecture

````mermaid
flowchart TD
    User["Visitor"]

    CF["Amazon CloudFront"]
    S3["Private Amazon S3"]
    API["Amazon API Gateway"]
    Lambda["AWS Lambda"]
    DDB["Amazon DynamoDB"]

    GitHub["GitHub"]
    Actions["GitHub Actions"]
    OIDC["GitHub OIDC"]
    IAM["AWS IAM Deploy Role"]

    User -->|HTTPS| CF
    CF -->|Origin Access Control| S3

    User -->|Visitor counter request| API
    API --> Lambda
    Lambda -->|Atomic update| DDB

    GitHub -->|Push to master| Actions
    Actions --> OIDC
    OIDC -->|Assume role| IAM
    IAM -->|Sync site| S3
    IAM -->|Invalidate cache| CF

The site uses:

- Amazon S3 for private static-site storage
- Amazon CloudFront for HTTPS delivery and caching
- Origin Access Control to keep the S3 bucket private
- Amazon API Gateway for the visitor-counter API
- AWS Lambda for serverless application logic
- Amazon DynamoDB for atomic visitor-count persistence
- Terraform for infrastructure as code
- GitHub Actions for continuous deployment
- GitHub OIDC for short-lived AWS authentication

## Design Goals

This implementation emphasizes:

- zero intentional AWS spend
- infrastructure as code
- least-privilege access
- no long-lived AWS access keys
- independently validated infrastructure changes
- small, reviewable deployment increments

## Architecture Decisions

### Private S3 Origin

The S3 bucket is not publicly accessible. CloudFront accesses objects
through Origin Access Control.

### Atomic Visitor Counter

The Lambda function uses a DynamoDB atomic update rather than a
read-modify-write sequence, avoiding lost updates under concurrency.

### Keyless CI/CD

GitHub Actions authenticates to AWS using OpenID Connect and assumes a
narrowly scoped deployment role. No AWS access keys are stored in
GitHub.

### Cost Control

The project was designed around a strict zero-spend goal. AWS resources
were evaluated for pricing before provisioning, and a zero-spend AWS
Budget was configured before application infrastructure was created.

## Repository Structure

```text
.
├── .github/workflows/   # CI/CD
├── lambda/              # Visitor-counter Lambda
├── scripts/             # Local deployment tooling
├── site/                # Static resume
└── terraform/           # AWS infrastructure

### Deployment

Changes under site/ pushed to master trigger GitHub Actions.

The workflow:

1.authenticates to AWS through GitHub OIDC
1.synchronizes site/ to S3
1.creates a CloudFront invalidation
Local Development
Terraform uses the `resume-challenge` AWS CLI profile with temporary credentials. If the session expires, reauthenticate with:

```bash
aws login --profile resume-challenge
TBD

### Infrastructure

AWS infrastructure is managed with Terraform under [`terraform/`](terraform/).

Terraform manages the supporting cloud resources, while static site content is deployed separately through GitHub Actions or the local deployment script.

The current infrastructure includes:

- A private Amazon S3 bucket for static site content
- An Amazon CloudFront distribution with Origin Access Control
- An Amazon DynamoDB table for visitor-count persistence
- An AWS Lambda function for the visitor counter
- An Amazon API Gateway HTTP API exposing the counter endpoint
- IAM roles and policies using least-privilege permissions
- A GitHub OpenID Connect provider and deployment role for keyless CI/CD

### Terraform Workflow

Initialize the working directory:

```bash
terraform -chdir=terraform init

### What I Learned

## What I Learned
content.
- **Prefer temporary credentials.** Local AWS access uses temporary login sessions, while GitHub Actions uses OIDC to assume a deployment role. No long-lived AWS access keys are required.
- **Least privilege is easier when responsibilities are narrow.** The Lambda role can update only the visitor-counter table, while the GitHub deployment role can only publish site content and invalidate CloudFront.
- **Atomic operations matter even in small projects.** The visitor counter uses a DynamoDB atomic update instead of a read-modify-write sequence, avoiding race conditions.
- **Separate infrastructure from application deployment.** Terraform manages AWS resources, while normal site updates are deployed independently through GitHub Actions.
- **Reviewing plans is part of the workflow.** Each infrastructure change was validated with `terraform fmt`, `terraform validate`, and `terraform plan` before applying it.

The Cloud Resume Challenge turned out to be less about building a resume page and more about connecting infrastructure, security, application code, deployment automation, and cost awareness into one coherent system.
This project reinforced that the interesting part of cloud engineering is often not creating resources, but understanding the boundaries around them.

A few lessons stood out:

- **Validate assumptions early.** I checked local tooling, AWS identity, account type, Free Tier behavior, and Terraform plans before provisioning resources. That caught several issues before they became expensive or difficult to unwind.
- **Free Tier does not automatically mean zero cost.** Service pricing, account-plan behavior, logging, DNS, public IPs, and optional features all need to be evaluated independently.
- **Keep public access at the edge.** The S3 bucket remains private, with CloudFront Origin Access Control providing the only read path for site
````
