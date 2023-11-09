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


## Working notes are below

### Run the commands below the first time the environment is created
```
sudo cp -r /opt/bitnami/resourcespace/filestore.old/* /opt/bitnami/resourcespace/filestore
sudo chown -R bitnami:daemon /opt/bitnami/resourcespace/filestore
sudo chmod -R 775 /opt/bitnami/resourcespace/filestore
```
### How to restart Resourcespace
```
sudo /opt/bitnami/ctlscript.sh restart
```

### Command to get the old password (for backup)
```
cat /opt/bitnami/resourcespace/include/config.php | grep mysql_password
```

### Command to back up the database so we can restore it onto RDS
```
/opt/bitnami/mariadb/bin/mariadb-dump -u bn_resourcespace -p<local_passowrd> bitnami_resourcespace | sudo tee /mnt/s3-backup/resourcespace.sql
```

### Command to restore resourcespace db onto RDS
```
opt/bitnami/mariadb/bin/mysql --host=bcparks-dam-mysql-cluster.cluster-cgzxkys12jpl.ca-central-1.rds.amazonaws.com --user=admin --password=<rds_passowrd> resourcespace < resourcespace.sql
```

### Debugging issues

Errors are in `/opt/bitnami/apache2/logs/error_log`
