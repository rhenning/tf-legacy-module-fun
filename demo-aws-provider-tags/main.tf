terraform {
  required_providers {
    aws = {
      version = "~> 3.40"
      source  = "hashicorp/aws"
    }
  }
}

variable "region" {
  default = "us-east-1"
}

provider "aws" {
  region = var.region

  // default tags will be inherited automatically by every resource
  // created by this instance of the aws provider, which is helpful.
  // unfortunately, things go pear-shaped real fast when any tag key
  // exists in both provider tags and resource tags, which makes the
  // feature cumbersome to use. at best, `terraform plan` will show
  // a perpetual diff and call the resource API to perform an update
  // every time `apply` is run. at worst, the provider can error due
  // to tags suddenly showing up on resources, or end in a provider
  // panic.
  default_tags {
    tags = {
      repo = "github.com/rhenning/tf-legacy-module-fun"
    }
  }
}

resource "aws_security_group" "_" {
  tags = {
    environment = "test"
    owner       = "sre-rhenning"

    // don't add tags on resources that are also listed in provider tags.
    // it probably won't go as well as you hope, even if the resource tag
    // is an override with a different value. the behavior isn't ideal. i
    // might even suggest that the feature is best avoided until some of
    // the runtime kinks are worked out, but ymmv.
  }
}

output "sg" {
  value = aws_security_group._
}
