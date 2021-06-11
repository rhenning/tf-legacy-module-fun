# legacy modules often declare explicit provider configuration, such as the
# example with region=x here. this is extremely common but not ideal, as our
# demo will show.

variable primary_bucket {}
variable primary_region {}
variable replica_bucket {}
variable replica_region {}
variable tags {}

provider aws {
  alias  = "primary"
  region = var.primary_region
}

provider aws {
  alias  = "replica"
  region = var.replica_region
}

resource aws_s3_bucket primary {
  provider = aws.primary
  bucket   = var.primary_bucket
  tags     = var.tags

  replication_configuration {
    role = aws_iam_role.replicate.arn

    rules {
      status = "Enabled"

      destination {
        bucket = aws_s3_bucket.replica.arn
      }
    }
  }
}

resource aws_s3_bucket replica {
  provider = aws.replica
  bucket   = var.replica_bucket
  tags     = var.tags
}

data aws_iam_policy_document assume {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

data aws_iam_policy_document replicate {
  statement {
    resources = ["arn:aws:s3:::${var.primary_bucket}"]

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
  }

  statement {
    resources = ["arn:aws:s3:::${var.primary_bucket}/*"]

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
  }

  statement {
    resources = ["arn:aws:s3:::${var.replica_bucket}/*"]

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
  }
}

resource aws_iam_role replicate {
  provider           = aws.primary
  name               = "${var.primary_bucket}-${var.replica_bucket}-s3-repl"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags

  inline_policy {
    name   = "replicate"
    policy = data.aws_iam_policy_document.replicate.json
  }
}
