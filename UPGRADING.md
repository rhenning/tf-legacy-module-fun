## terraform version upgrades

This document contains some guidance on safely upgrading Terraform and refactoring  
legacy projects to work with newer versions of Terraform.

## preparation

* install [tfenv](https://github.com/tfutils/tfenv) in your development environment 
  and manage appropriate `.terraform-version` files. do not skip this. using a
  consistent version of terraform for each project is critical when remote state
  is involved. not doing this can result in nasty surprises if terraform decides
  to automatically migrate to a newer version of the statefile
* authenticate to the target AWS account, if necessary
* install `tflint`, Terratest, the `aws` CLI, and any other necessary tools for
  testing or troubleshooting

## testing the upgrade

* increment any `.terraform-version` files to the latest version available in
  in the _current_ patch series before moving on to minor or major version
  upgrades. 
  Note: available versions can be found on the [Hashicorp release site](https://releases.hashicorp.com/terraform/)
  * _ex:_ if `0.12.6`, bump to `0.12.31` and test first, before going to `0.13.x`
* pull a copy of the remote state to your local filesystem and create an override
  so that terraform prefers local state, rather than remote state, during your
  refactor. ***take care not to commit `_override.tf` or `terraform.tfstate` to git.***


        : cd into a terraform root module directory
        terraform init
        terraform state pull > terraform.tfstate
        printf 'terraform {\n  backend "local" {}\n}\n' > _override.tf
        terraform init -reconfigure


terraform is now using the local copy of the state file (in `./terraform.tfstate`)
and has upgraded it to work with whatever version of terraform is now specified
in `.terraform-version`.

**it is extremely important** that you ***do not run `terraform apply` in this
"detached state" mode.*** doing so can result in race conditions with continuous
delivery systems or other terraform users working on the same project. just in
case, you can use `terraform state push` to sync a local copy of state with
a remote state backend, but this is out of scope for this section.

at this point, you should be able to change code as needed, and run `terraform
plan` without inadvertently affecting the contents of remote state.

if all goes well, `terraform plan` should report `No changes. Infrastructure is
up-to-date.` if terraform crashes or generates a terrifying-looking diff, then
that's a good indication that existing code needs to be refactored to work with
the target upgrade version.

note that running `terraform plan` implicity runs `terraform refresh`,
which will modify state in many versions of terraform. this is why it is critical
to create a _local_ copy of state before testing `terraform plan` with a newer
version of terraform. when using the `s3` state backend, it is strongly
recommended that s3 object versioning is enabled on the state bucket as a hedge
against failed or inadvertent upgrades.

## rut-roh

so... you accidentally used a bleeding-edge `terraform-SNAPSHOT` from trunk and
upgraded your production remote state file, eh?

now when terraform is run from continuous delivery, it reports `Error: state
snapshot was created by Terraform vX.Y.Z, which is newer than current vA.B.C`.
this can be a real pain, but if s3 object versioning is enabled on the remote
state bucket, _and `terraform apply` has not been executed_, then it's not such
a big deal to roll back. if `apply` _has_ been executed, production infrastructure
modified, and your production environment is not on fire, then congrats... you
might as well roll forward and upgrade.


to roll back an inadvertent terraform statefile version upgrade:

* notify your team that any deployments, terraform development, branch builds or
  pull requests for the affected project should cease immediately.
* freeze all delivery or deployment jobs that might modify infrastructure or
  run `terraform plan`, including branch builds and pull requests. you may wish
  to create a terraform state lock if using a suitable lock backend, such as
  dynamodb.
* revert any changes to `.terraform-version` files.
* inspect the s3 object versions of the tfstate file and find the version
  of tfstate from just before the upgrade.
* promote the version from just before the upgrade to current. the following
  aws cli oneliner can be used for that purpose:
        ```
        ```
* run `terraform init && terraform plan` using the old version of Terraform.
* terraform should report `No changes. Infrastructure is up-to-date.`
* if terraform reports that it wants to make changes, it is possible that a
  `terraform apply` was executed. if rollback to the previous version of
  terraform and its statefile version is desired, then it may be necessary
  to engage in "state surgery" with `terraform import`. this process is
  beyond the scope of this section.
