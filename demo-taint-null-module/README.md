This is a demo module to play around with `terraform taint` and see the effect
it has on resources, especially when used with the common pattern of attaching
the `local-exec` provisioner to a `null_resource` in order to get Terraform to
run a script.

Try this:

```
terraform init
terraform apply -auto-approve
terraform apply -auto-approve
terraform taint module._.time_sleep.zzz
terraform apply -auto-approve
terraform apply -auto-approve
terraform destroy -auto-approve
```

Now take a look at the source code of [`main.tf`](main.tf) in this directory,
and the module it includes from
[`../modules/blocked-null-hack/main.tf`](../modules/blocked-null-hack/main.tf).
