# BC Parks ResourceSpace Digital Asset Management System

[ResourceSpace](https://www.resourcespace.com/) ([packaged by Bitnami](https://bitnami.com/stack/resourcespace/cloud/aws)) is the digital asset management software used to power the BC Parks DAM.  
ResourceSpace is launched and configured on the BC Government's private AWS cloud using the scripts contained in this repo.

## Prerequesites

* Fork this repo
* Install the AWS cli
* Install terragrunt and terraform

## Updating dev/test/prod

* Connect to the BC Government AWS login application and get your credentials to paste into a terminal
* `cd src/terraform/terragrunt/<ENVIRONMENT>`
* `terragrunt apply`

## Tearing down an environment

* Connect to the BC Government AWS login application and get your credentials to paste into a terminal
* `cd src/terraform/terragrunt/<ENVIRONMENT>`
* `terragrunt destroy`