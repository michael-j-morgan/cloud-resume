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

TBD

### Infrastructure

TBD

### What I Learned

TBD
````
