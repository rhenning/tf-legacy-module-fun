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

# init, plan, apply, then comment this module out in an attempt to remove it
# and try a plan to see terraform freak out due to legacy module embedded
# provider config. this error will be generated:

# Error: Provider configuration not present
#
# To work with module.legacy.aws_s3_bucket_object._ its original provider
# configuration at module.legacy.provider.aws is required, but it has been
# removed. This occurs when a provider configuration is removed while objects
# created by that provider still exist in the state. Re-add the provider
# configuration to destroy module.legacy.aws_s3_bucket_object._, after which you
# can remove the provider configuration again.
#
#
# Error: Provider configuration not present
#
# To work with module.legacy.data.aws_s3_bucket._ its original provider
# configuration at module.legacy.provider.aws is required, but it has been
# removed. This occurs when a provider configuration is removed while objects
# created by that provider still exist in the state. Re-add the provider
# configuration to destroy module.legacy.data.aws_s3_bucket._, after which you
# can remove the provider configuration again.

module legacy {
  source = "./legacy-module"

  # note that we're explicitly injecting a region here, used by the inner
  # provider, rather than letting the module inherit provider config
  region  = "us-east-1"
  bucket  = "my-tf-test-bucket-blabla"
  object  = "tf-legacy-module-fun/testobject-legacy.txt"
  content = random_pet._.id

  tags = {
    repo = "github.com/rhenning/tf-legacy-module-fun"
  }
}


# in contrast, this module inherits the provider config and tags from
# this root/parent module

module mainstream {
  source = "./mainstream-module"

  bucket  = "my-tf-test-bucket-blabla"
  object  = "tf-legacy-module-fun/testobject-mainstream.txt"
  content = random_pet._.id
}


# the workaround is to run this before removing the legacy module
# from the terraform code:
#
# terraform plan -destroy -target module.legacy -out tfplan.json
#
# review the plan and make sure it is destroying only what you expect
#
# then run:
#
# terraform apply tfplan.json
#
# now, comment out the legacy module and your tfplan will work, showing:
# No changes. Infrastructure is up-to-date.