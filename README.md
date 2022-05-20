# Virtual Machines Application Architecture
![Virtual Machines Application Architecture](./images/vm-app-architecture.png)
## Setup
- Fork this repo
- Enable github actions
#### Github Secrets
you'll need to add two github secrets:
  - `LICENCEPLATE` is the 6 character licence plate associated with your project set e.g. `abc123`
  - `TFC_TEAM_TOKEN` is the token used to access the terraform cloud runner.

#### Pipeline
This branch based github actions will trigger on a pull request creation and merge.
- Creating a pull request on respective branches(dev,test,main) will run a `terraform plan` and outline everything that will be deployed into your AWS accounts(dev,test,prod), but will not create anything.
- Merging into `dev branch` will run a `terraform apply` and your AWS assets will be deployed into your `dev` accounts.
- Merging into `test branch` will run a `terraform apply` and your AWS assets will be deployed into your `test` accounts.
- Merging into `main branch` will run a `terraform apply` and your AWS assets will be deployed into your `Prod` accounts.
>NOTE: make sure you are creating pull requests/ merging within your fork