This is a demo module to play around with `terraform taint` and see the effect
it has on resources, especially when used with the common pattern of attaching
the `local-exec` provisioner to a `null_resource` in order to get Terraform to
run a script.

Try this:

```
terraform init
terraform apply
terraform apply
terraform taint module._.time_sleep.zzz
terraform apply
terraform apply
terraform destroy
```

Now take a look at the source code of [`main.tf`](main.tf) in this directory,
and the module it includes from
[`../modules/blocked-null-hack/main.tf`](../modules/blocked-null-hack/main.tf).

Note that Terraform only executes the `local-exec` provisioner and prints
`HALLO THERE.` once, as long as the resource attached to the provisioner (and
the provisioner itself) have both applied successfully and exist in tfstate.

`taint` marks a resource that has been successfully applied and stored in
state as "dirty", which results in Terraform recreating that resource along
with any of its dependencies.
