#!/usr/bin/env bash
set -euo pipefail

PROFILE="resume-challenge"
TERRAFORM_DIR="terraform"
SITE_DIR="site"

bucket="$(
    terraform -chdir="$TERRAFORM_DIR" output -raw resume_bucket_name
)"

distribution_id="$(
    terraform -chdir="$TERRAFORM_DIR" output -raw cloudfront_distribution_id
)"

echo "Deploying to s3://$bucket"

aws s3 sync "$SITE_DIR/" "s3://$bucket/" \
    --profile "$PROFILE" \
    --delete

echo "Invalidating CloudFront distribution $distribution_id"

aws cloudfront create-invalidation \
    --distribution-id "$distribution_id" \
    --paths "/*" \
    --profile "$PROFILE"
