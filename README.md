# Virtual Machines Application Architecture
![Virtual Machines Application Architecture](./images/vm-app-architecture.png)

## Setup
- Fork this repo
- Enable github actions
#### Github Secrets
This repository use [Github OpenID Connect](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) to authenticate directly to AWS assuming an IAM role.

The required environment Secrets are:
  - `TERRAFORM_DEPLOY_ROLE_ARN` This is the ARN of IAM Role used to deploy resources through the Github action authenticate with the GitHub OpenID Connect. You also need to link that role to the correct IAM Policy.
  - - To access the `TERRAFORM_DEPLOY_ROLE_ARN` you need to create it beforehand manually in each account. Then you have to add the right arn for each Github environment.
  To create it you need can use this example of thrust relationship :
  ```
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::<accound_id>:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:<Github_organization>/<repo_name>:ref:refs/heads/<Your_branch>"
                },
                "ForAllValues:StringEquals": {
                    "token.actions.githubusercontent.com:iss": "https://token.actions.githubusercontent.com",
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
  ```

For the following secret they are global for every account so you can put them as Github repository _Secrets_
  - `LICENCEPLATE` is the 6 character licence plate associated with your project set e.g. `abc123`
  - `S3_BACKEND_NAME` is the name of the S3 Bucket name used to store the Terraform state.


#### Pipeline
This branch based github actions will trigger on a pull request creation and merge.
- Creating a pull request on respective branches(dev,test,main) will run a `terraform plan` and outline everything that will be deployed into your AWS accounts(dev,test,prod), but will not create anything.
- Merging into `dev branch` will run a `terraform apply` and your AWS assets will be deployed into your `dev` accounts.
- Merging into `test branch` will run a `terraform apply` and your AWS assets will be deployed into your `test` accounts.
- Merging into `main branch` will run a `terraform apply` and your AWS assets will be deployed into your `Prod` accounts.
>NOTE: make sure you are creating pull requests/ merging within your fork