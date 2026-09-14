resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  tags = {
    Project   = "cloud-resume"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:michael-j-morgan@13445380/cloud-resume@1369258659:ref:refs/heads/master",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "cloud-resume-github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Project   = "cloud-resume"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    sid = "DeployResumeSite"

    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.resume.arn,
      "${aws_s3_bucket.resume.arn}/*",
    ]
  }

  statement {
    sid = "InvalidateResumeCloudFront"

    actions = [
      "cloudfront:CreateInvalidation",
    ]

    resources = [
      aws_cloudfront_distribution.resume.arn,
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "cloud-resume-site-deploy"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}
