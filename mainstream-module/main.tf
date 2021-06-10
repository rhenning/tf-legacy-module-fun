# legacy modules declare their own providers rather than inheriting
# them from the parent. when multiple instances of a provider are
# necessary, say to coordinate changes across two different AWS
# regions, aliases can be used instead.
#
# https://www.terraform.io/docs/language/modules/develop/providers.html#legacy-shared-modules-with-provider-configurations

# no explicit provider config declared. provider config is inherited from the
# parent or aliases are explicitly injected.

variable bucket {}
variable object {}
variable content {}

data aws_s3_bucket _ {
  bucket = var.bucket
}

resource aws_s3_bucket_object _ {
  bucket  = data.aws_s3_bucket._.bucket
  key     = var.object
  content = var.content
  # tags{} are inherited from provider default_tags{}
}

output version_id {
  value = aws_s3_bucket_object._.version_id
}
