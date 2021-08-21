variable "zzz_time" {}

resource "time_sleep" "zzz" {
  create_duration = var.zzz_time
}

resource "null_resource" "say_hi" {
  triggers = {
    "zzz" = time_sleep.zzz.id
  }

  provisioner "local-exec" {
    command = "echo HALLO THERE."
  }
}
