# legacy modules declare their own providers rather than inheriting
# them from the parent. when multiple instances of a provider are
# necessary, say to coordinate changes across two different AWS
# regions, aliases can be used instead.
#
# https://www.terraform.io/docs/language/modules/develop/providers.html#legacy-shared-modules-with-provider-configurations

# note the explicit configuration with region=x here. extremely 
# common but not ideal, as our demo will show.
provider aws {
  region = var.region
}

variable region {}
variable bucket {}
variable object {}
variable content {}
variable tags {}

data aws_s3_bucket _ {
  bucket = var.bucket
}

resource aws_s3_bucket_object _ {
  bucket  = data.aws_s3_bucket._.bucket
  key     = var.object
  content = var.content
  tags    = var.tags
}

output version_id {
  value = aws_s3_bucket_object._.version_id
}
