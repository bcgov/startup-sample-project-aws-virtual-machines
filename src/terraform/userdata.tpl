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


# MOUNT THE EBS PERISTENT VOLUME
# This volume contains the resourcespace filestore. We tried using S3 but it was slow and unreliable.
# Note that this volume has to be attached and mounted in a script. Mounting a volume to a scalable launch 
# configuration is not supported by terraform (you can only connect a volume to a single instance in Terrafom).
#
echo '### Mounting the EBS persistent volume ###'
sudo apt update -y
sudo apt-get install awscli -y
EC2_INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`"
ECS_VOLUME_ID="`aws ec2 describe-volumes --region ca-central-1 --filters Name=tag:Name,Values="ResourceSpace filestore" --query "Volumes[*].{ID:VolumeId}" --output text`"
aws ec2 attach-volume --volume-id $ECS_VOLUME_ID --instance-id $EC2_INSTANCE_ID --device "/dev/sdf" --region="ca-central-1"
sleep 2
sudo mount -t auto -v /dev/sdf /opt/bitnami/resourcespace/filestore  # replace the default filestore folder


# MOUNT THE S3 BUCKET
# The S3 bucket /mnt/s3-backup is used for backups and file transfers. You can use
# the AWS web console to upload and download data into this bucket from your computer.
#
echo "### Mounting the S3 bucket ###"
sudo apt-get install s3fs -y
sudo mkdir /mnt/s3-backup
sudo s3fs bcparks-dam-${target_env}-backup /mnt/s3-backup -o iam_role=BCParks-Dam-EC2-Role -o use_cache=/tmp -o allow_other -o uid=0 -o gid=1 -o mp_umask=002  -o multireq_max=5 -o use_path_request_style -o url=https://s3-${aws_region}.amazonaws.com


# CUSTOMIZE THE BITNAMI RESOURCESPACE CONFIG
# Download all the files from our git repo to get our customized copy of config.php
#
echo '### Customizing the Bitnami Resourcespace config ###`
sudo -u bitnami mkdir -p /home/bitnami/repos
cd /home/bitnami/repos
sudo apt-get install git -y
sudo -u bitnami git clone ${git_url} bcparks-dam
# TODO: copy the config.php file to overwrite the resourcespace config
# TODO: use values from AWS secrets manager secrets to append settings to the file 



# MY WORKING NOTES ARE BELOW THIS LINE

# just complete the steps below once during setup (need to figure out how to check if it's already done to automate it)

# 1. create the volume from the gui with the name 'ResourceSpace filestore'
#     -- 10GB / gp2 / default settings (you can make it bigger later from the web interface)
#     -- for some reason Terraform permissions won't allow us to create it
#
# 2. run the commands below after the volume is created
#   cd /opt/bitnami/resourcespace
#   sudo umount /opt/bitnami/resourcespace/filestore
#   sudo cp -r filestore filestore.old
#   sudo mkfs.ext4 /dev/sdf
#   sudo mount -t auto -v /dev/sdf /opt/bitnami/resourcespace/filestore
#   sudo cp -R filestore.old/* filestore
#   sudo rm -rf filestore.old
#   sudo chown -R bitnami:daemon filestore
#   sudo chmod -R 775 filestore


# command to back up the database so we can restore it onto RDS
# /opt/bitnami/mariadb/bin/mariadb-dump -u bn_resourcespace -p<password> bitnami_resourcespace > /mnt/s3-backup/resourcespace.sql

# command to restart ResoureSpace
# sudo /opt/bitnami/ctlscript.sh restart
