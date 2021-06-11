# legacy modules often declare explicit provider configuration, such as the
# example with region=x here. this is extremely common but not ideal, as our
# demo will show.

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
