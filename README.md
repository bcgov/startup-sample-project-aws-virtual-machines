# BC Parks ResourceSpace Digital Asset Management System

[ResourceSpace](https://www.resourcespace.com/) ([packaged by Bitnami](https://bitnami.com/stack/resourcespace/cloud/aws)) is the digital asset management software used to power the BC Parks DAM.  
ResourceSpace is launched and configured on the BC Government's private AWS cloud using the scripts contained in this repo.

Terraform code is heavily based on the *[startup-sample-project-aws-drupal-containers-terraform-modules](https://github.com/bcgov/startup-sample-project-aws-drupal-containers-terraform-modules)* app.  

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

## Extra steps to complete the first time you set up an instance

Go to the EC2 instance bcparks-dam-vm via the AWS web console and click "Connect", then select "Session Manager". The Session Manager will be disabled initially, but it will become enabled after the SSM Agent is installed by the file `src/terraform/userdata.tpl`.

### Get the default user creds for ResourceSpace
Save these for later. They will be different next time the vm starts. 
```
sudo cat /home/bitnami/bitnami_credentials
```

### Get some setting from the default config.php file installed by Bitnami
Update `resourcespace_secrets` in AWS Secrets Manager with the values from `$spider_password`, `$scramble_key` and `$api_scramble_key`.
You will need `$mysql_password` for the next step.
```
cat /opt/bitnami/resourcespace/include/config.php.bitnami | grep "scramble\|password"
```

### Back up the local database
Use the `$mysql_password` variable value from above for the `<local_password>`.
```
/opt/bitnami/mariadb/bin/mariadb-dump --add-drop-table -u bn_resourcespace -p<local_passowrd> bitnami_resourcespace | sudo tee /mnt/s3-backup/resourcespace.sql
```

### Restore the database onto RDS
The rds_password and host name are in the AWS Secrets Manager in "rds-db-credentials"
```
/opt/bitnami/mariadb/bin/mysql --host=<host_name of rds endpoint> --user=admin --password=<rds_passowrd> resourcespace <  /mnt/s3-backup/resourcespace.sql
```

### Run the commands below to copy the default filestore data
```
sudo cp -r /opt/bitnami/resourcespace/filestore.bitnami/* /opt/bitnami/resourcespace/filestore
sudo chown -R bitnami:daemon /opt/bitnami/resourcespace/filestore
sudo chmod -R 775 /opt/bitnami/resourcespace/filestore
```

### After all the steps above are complete...
Make a small change to userdata.tpl, (such as adding a space or blank line) and run `terragrunt apply` again.

## Transferring files

There is an S3 bucket called `bcparks-dam-dev-backup` which is accessible from the AWS web GUI. You can upload files to it with your browser. The bucket is mounted under `/mnt/s3-backup` on the VM. 

## Debugging tips

ResourceSpace errors are in `/opt/bitnami/apache2/logs/error_log`

### How to restart Resourcespace
```
sudo /opt/bitnami/ctlscript.sh restart
```