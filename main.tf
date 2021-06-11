terraform {
  backend "s3" {
    bucket = "my-tf-test-bucket-blabla"
    key    = "github.com/rhenning/tf-legacy-module-fun/terraform.tfstate"
    region = "us-east-1"
  }
}

provider aws {
  region = "us-east-1"

  default_tags {
    tags = {
      repo = "github.com/rhenning/tf-legacy-module-fun"
    }
  }
}

provider aws {
  alias  = "uw2"
  region = "us-west-2"

  default_tags {
    tags = {
      repo = "github.com/rhenning/tf-legacy-module-fun"
    }
  }
}

resource random_pet primary {
  prefix = "pri"
  length = 2
}

resource random_pet replica {
  prefix = "rep"
  length = 2
}

# init, plan, apply, then comment out the legacy module in an attempt to
# remove its resources. running a plan will cause terraform to freak out
# as outlined in `README.md`, due to explicit embedded provider config.

module legacy {
  source = "./legacy-module"

  # note that we're explicitly injecting a region here, used by the inner
  # provider, rather than letting the module inherit our provider config.
  primary_region = "us-east-1"
  primary_bucket = "${random_pet.primary.id}-lm"
  replica_region = "us-west-2"
  replica_bucket = "${random_pet.primary.id}-lm"

  tags = {
    repo = "github.com/rhenning/tf-legacy-module-fun"
  }
}


# in contrast, this module inherits our provider config and tags from
# this root/parent module

module mainstream {
  source = "./mainstream-module"

  primary_bucket = "${random_pet.primary.id}-mm"
  replica_bucket = "${random_pet.primary.id}-mm"

  providers = {
    aws.primary = aws
    aws.replica = aws.uw2
  }
}
