#! /bin/bash

# INSTALL SSM AGENT
# This allows SSH access into the VM from the Session Manager web interface.
# This take a while to start up, so be patient. You can use the EC2 serial console
# to monitor progress before the Session Manager is ready.
#
echo '### Installing the SSM Agent ###'
mkdir /tmp/ssm
cd /tmp/ssm
wget -q https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb


# INSTALL AMAZON-EFS-UTILS
# We need to build this from source for Debian Linux. It isn't avaialble otherwise
#
echo '### Installing amazon-efs-utils ###'
sudo apt update -y
sudo apt-get install git binutils -y
sudo -u bitnami mkdir -p /home/bitnami/repos
cd /home/bitnami/repos
sudo -u bitnami git clone https://github.com/aws/efs-utils efs-utils
cd efs-utils
sudo -u bitnami ./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb


# MOUNT THE EFS PERISTENT FILESYSTEM
# This volume contains the resourcespace filestore. We tried using S3 but it was slow and unreliable.
# EBS wouldn't work either because the autoscaling group runs in 2 availability zones.  
#
echo '### Mounting the EFS filesystem ###'
cd /opt/bitnami/resourcespace
sudo cp -R filestore filestore.bitnami
sudo mount -t efs -o iam -o tls ${efs_dns_name}:/ ./filestore
sudo chown -R bitnami:daemon filestore*
sudo chmod -R 775 filestore*


# MOUNT THE S3 BUCKET
# The S3 bucket /mnt/s3-backup is used for backups and file transfers. You can use
# the AWS web console to upload and download data into this bucket from your computer.
#
echo '### Mounting the S3 bucket ###'
sudo apt-get install s3fs -y
sudo mkdir /mnt/s3-backup
sudo s3fs bcparks-dam-${target_env}-backup /mnt/s3-backup -o iam_role=BCParks-Dam-EC2-Role -o use_cache=/tmp -o allow_other -o uid=0 -o gid=1 -o mp_umask=002  -o multireq_max=5 -o use_path_request_style -o url=https://s3-${aws_region}.amazonaws.com


# CUSTOMIZE THE BITNAMI RESOURCESPACE CONFIG
# Download all the files from our git repo to get our customized copy of config.php
#
echo '### Customizing the Bitnami Resourcespace config ###'
cd /home/bitnami/repos
#sudo -u bitnami git clone ${git_url} bcparks-dam
BRANCH_NAME = "${branch_name}"
#sudo -u bitnami git clone -b $BRANCH_NAME ${git_url} bcparks-dam
sudo -u bitnami git clone -b rfiddler ${git_url} bcparks-dam

# use values from AWS secrets manager secrets to append settings to the file
tee -a bcparks-dam/src/resourcespace/files/config.php << END

# MySQL database settings
\$mysql_server = '${rds_endpoint}:3306';
\$mysql_username = '${mysql_username}';
\$mysql_password = '${mysql_password}';
\$mysql_db = 'resourcespace';

# Email settings
\$email_notify = '${email_notify}';
\$email_from = '${email_from}';

# Secure keys
\$spider_password = '${spider_password}';
\$scramble_key = '${scramble_key}';
\$api_scramble_key = '${api_scramble_key}';

END
# SimpleSAML config
sudo cat bcparks-dam/src/resourcespace/files/simplesaml-config-1.php | tee -a bcparks-dam/src/resourcespace/files/config.php
tee -a bcparks-dam/src/resourcespace/files/config.php << END
    'technicalcontact_name' => '${technical_contact_name}',
    'technicalcontact_email' => '${technical_contact_email}',
    'secretsalt' => '${secret_salt}',
    'auth.adminpassword' => '${auth_admin_password}',
    'database.username' => '${saml_database_username}',
    'database.password' => '${saml_database_password}',
END
sudo cat bcparks-dam/src/resourcespace/files/simplesaml-config-2.php | tee -a bcparks-dam/src/resourcespace/files/config.php
sudo cat bcparks-dam/src/resourcespace/files/simplesaml-authsources-1.php | tee -a bcparks-dam/src/resourcespace/files/config.php
tee -a bcparks-dam/src/resourcespace/files/config.php << END
        'entityID' => '${sp_entity_id}',
        'idp' => '${idp_entity_id}',
END
sudo cat bcparks-dam/src/resourcespace/files/simplesaml-authsources-2.php | tee -a bcparks-dam/src/resourcespace/files/config.php
tee -a bcparks-dam/src/resourcespace/files/config.php << END
\$simplesamlconfig['metadata']['${idp_entity_id}'] = [
    'entityID' => '${idp_entity_id}',
END
sudo cat bcparks-dam/src/resourcespace/files/simplesaml-metadata-1.php | tee -a bcparks-dam/src/resourcespace/files/config.php
tee -a bcparks-dam/src/resourcespace/files/config.php << END
        'Location' => '${single_signon_service_url}',
END
sudo cat bcparks-dam/src/resourcespace/files/simplesaml-metadata-2.php | tee -a bcparks-dam/src/resourcespace/files/config.php
tee -a bcparks-dam/src/resourcespace/files/config.php << END
        'Location' => '${single_logout_service_url}',
END
sudo cat bcparks-dam/src/resourcespace/files/simplesaml-metadata-3.php | tee -a bcparks-dam/src/resourcespace/files/config.php
tee -a bcparks-dam/src/resourcespace/files/config.php << END
        'X509Certificate' => '${x509_certificate}',
END
sudo cat bcparks-dam/src/resourcespace/files/simplesaml-metadata-4.php | tee -a bcparks-dam/src/resourcespace/files/config.php


# copy the customized config.php file to overwrite the resourcespace config
cd /opt/bitnami/resourcespace/include
sudo cp config.php config.php.bitnami
sudo cp /home/bitnami/repos/bcparks-dam/src/resourcespace/files/config.php .
sudo chown bitnami:daemon config.php
sudo chmod 664 config.php


# CLEAR THE TMP FOLDER
#
echo '### Clear the tmp folder ###'
sudo rm -rf /opt/bitnami/resourcespace/filestore/tmp/*


# copy the favicon and header image
cd /opt/bitnami/resourcespace/filestore/system/config
sudo cp /home/bitnami/repos/bcparks-dam/src/resourcespace/files/header_favicon.png .
sudo cp /home/bitnami/repos/bcparks-dam/src/resourcespace/files/linkedheaderimgsrc.png .