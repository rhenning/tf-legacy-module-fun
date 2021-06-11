# note that no _explicit_ provider config is declared. the provider config is
# inherited from the parent via aliases that are explicitly injected.

terraform {
  required_providers {
    aws = {
      configuration_aliases = ["aws.primary", "aws.replica"]
    }
  }
}

# not ideal but a "bare" provider alias config is required for terraform 0.12
# tf >=0.13 can infer these from the configuration_aliases block alone.

provider aws {
  alias = "primary"
}

provider aws {
  alias = "replica"
}

# note the lack of any injected `region` being used to explicitly
# instantiate provider aliases. `tags{}` can be inherited from the
# parent module's aws providers' default_tags{} as a nice side effect.
variable primary_bucket {}
variable replica_bucket {}

resource aws_s3_bucket primary {
  provider = aws.primary
  bucket   = var.primary_bucket

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

  inline_policy {
    name   = "replicate"
    policy = data.aws_iam_policy_document.replicate.json
  }
}
