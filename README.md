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

### Get the default user creds for ResourceSpace (write these down)
```
sudo cat /home/bitnami/bitnami_credentials
```

### Command to get the local db password (for backup)
```
cat /opt/bitnami/resourcespace/include/config.php.old | grep mysql_password
```

### Command to get the scramble key
You'll need to update the scramble_key in the AWS Secrets Manager to match the db backup and credentials. I think this is like a system-wide salt for user passwords.

```
cat /opt/bitnami/resourcespace/include/config.php.old | grep "\$scramble_key"
```

### Command to back up the database so we can restore it onto RDS
```
/opt/bitnami/mariadb/bin/mariadb-dump --add-drop-table -u bn_resourcespace -p<local_passowrd> bitnami_resourcespace | sudo tee /mnt/s3-backup/resourcespace.sql
```

### Command to restore resourcespace db onto RDS
The rds_password and host name are in the AWS Secrets Manager in "rds-db-credentials"

```
/opt/bitnami/mariadb/bin/mysql --host=<host_name of rds endpoint> --user=admin --password=<rds_passowrd> resourcespace <  /mnt/s3-backup/resourcespace.sql
```

### Run the commands below the first time the environment is created to seed the filestore
```
sudo cp -r /opt/bitnami/resourcespace/filestore.old/* /opt/bitnami/resourcespace/filestore
sudo chown -R bitnami:daemon /opt/bitnami/resourcespace/filestore
sudo chmod -R 775 /opt/bitnami/resourcespace/filestore
```

## Transferring files

There is an S3 bucket called `bcparks-dam-dev-backup` which is accessible from the AWS web GUI. You can upload files to it with your browser. The bucket is mounted under /`mnt/s3-backup` on the VM. 

## Debugging tips

ResourceSpace errors are in `/opt/bitnami/apache2/logs/error_log`

### How to restart Resourcespace
```
sudo /opt/bitnami/ctlscript.sh restart
```

