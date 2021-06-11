# note that no explicit provider config is declared. the provider config is
# inherited from the parent or via aliases that are explicitly injected (in
# the case of modules that require multiple providers)

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
  # tags{} can be inherited from the parent provider's default_tags{}
}

output version_id {
  value = aws_s3_bucket_object._.version_id
}
