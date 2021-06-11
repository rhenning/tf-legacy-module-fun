## Problem

If your team uses a lot of Terraform modules, sooner or later you are bound
to run into the following class of error when removing a module definition
from your Terraform code:

```
Error: Provider configuration not present

To work with module.mybucket.aws_s3_bucket_object._ its original provider
configuration at module.mybucket.provider.aws is required, but it has been
removed. This occurs when a provider configuration is removed while objects
created by that provider still exist in the state. Re-add the provider
configuration to destroy module.mybucket.aws_s3_bucket_object._, after which you
can remove the provider configuration again.
```

It's reasonable to expect that removal of a `module _ {}` block from your
Terraform code would result in Terraform deleting the resources contained
within, just as Terraform would do for bare resources located outside of a
module.

## Explanation

[There is a catch, however.](https://www.terraform.io/docs/language/modules/develop/providers.html#legacy-shared-modules-with-provider-configurations)
Older versions of Terraform did not have the means to manage multiple
instances of a single provider type with different configurations and inject
those providers into modules. Consider a module that creates two S3 buckets
in different regions and configures replication between them. A common legacy
pattern for this might be to create a single module that accepts the following
variables:

```
primary_bucket_name
primary_bucket_region
replica_bucket_name
replica_bucket_region
```

and uses those variables to set up two instances of the AWS provider, one
per region. So far, so good. For the most part, this works as expected when 
creating new instances of modules and managing updates to the resources within.

_Removing_ an instance of a module designed in this way, however, removes the 
explicit provider configuration contained within. The provider config is
necessary for Terraform to manage the enclosed resources, which leads to the
error above.

## Workarounds

There are (at least) two "fixes" for this problem, and which you choose depends
on some mix of whether or not you  intend to continue using the affected
module code and your tolerance for running _ad-hoc_ Terraform commands outside
of the usual `init`, `plan`, `apply` lifecycle.

### Refactor the module

If you are keeping any instances of this module around to manage resources
long-term, it's probably worth
[refactoring the module to remove explicit provider configuration](https://www.terraform.io/docs/language/modules/develop/providers.html),
relying on inheritance or injected aliases instead. Once the inner module
has been refactored in this way, you should be able to
[bump any version constraints](https://www.terraform.io/docs/language/modules/sources.html#selecting-a-revision)
to use the refactored module, then run `terraform init`, `terraform plan`, and
`terraform apply`, just as if performing a normal module version upgrade.

Once that is complete, you can remove the desired `module _ {}` block from 
source and Terraform should be able to delete the module's resources without
incident.

You may also prefer this strategy if your team is averse to executing
_ad-hoc_ Terraform changes. It takes a few more iterations, but has the
benefit of fitting into an infrastructure-as-code CI/CD workflow. 

### Targeted Destroy

In some cases, the affected module is not being maintained going forward, or 
upgrading to the latest version has other undesirable side effects. In this
case, you can perform a [targeted destroy](https://www.terraform.io/docs/cli/commands/plan.html#resource-targeting) before removing the module instance
from source.

Let's stick with our example of a module that manages two s3 buckets with
replication. If the module being removed is declared as
`module my_buckets {}`:

- First generate a terraform plan and *write it to a file*:

    ```
    terraform init
    terraform plan -destroy -target module.my_buckets -out tfplan.json
    ```

- It is *strongly recommended* that plan output is shared with
  and reviewed by teammates before the next step is executed. Be certain
  that the plan's diff output indicates only the resource(s) that you intend to
  delete. Writing the plan to a file ensures that the diff you see is what
  will be applied. There is no coming back from the next step. Measure
  thrice, cut once. You may also wish to pause any automated processes,
  such as CI/CD pipelines, that could inadvertently run and interfere
  with this ad-hoc change. The use of [state locking](https://www.terraform.io/docs/language/state/locking.html)
  is also recommended.
- Once you are satisfied that the plan includes only what is expected, run:

    ```
    terraform apply tfplan.json
    ```
- Now remove the module instance from source and `terraform plan` should
  no longer generate an error, instead displaying:
    ```
    No changes. Infrastructure is up-to-date.
    ```
- Merge any outstanding PRs for this change.
- Return systems to BAU.

## Example Code

See [`main.tf`](main.tf) in this directory, along with the provided submodules,
for examples of legacy and mainstream provider design patterns.
