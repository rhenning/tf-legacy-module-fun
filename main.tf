terraform {
  backend "s3" {
    bucket = "my-tf-test-bucket-blabla"
    key    = "tf-legacy-module-fun/terraform.tfstate"
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

resource random_pet _ {}

# init, plan, apply, then comment out the legacy module in an attempt to
# remove its resources. running a plan will cause terraform to freak out
# as outlined in `README.md`, due to explicit embedded provider config.

module legacy {
  source = "./legacy-module"

  # note that we're explicitly injecting a region here, used by the inner
  # provider, rather than letting the module inherit our provider config.
  region  = "us-east-1"
  bucket  = "my-tf-test-bucket-blabla"
  object  = "tf-legacy-module-fun/testobject-legacy.txt"
  content = random_pet._.id

  tags = {
    repo = "github.com/rhenning/tf-legacy-module-fun"
  }
}


# in contrast, this module inherits our provider config and tags from
# this root/parent module

module mainstream {
  source = "./mainstream-module"

  bucket  = "my-tf-test-bucket-blabla"
  object  = "tf-legacy-module-fun/testobject-mainstream.txt"
  content = random_pet._.id
}
