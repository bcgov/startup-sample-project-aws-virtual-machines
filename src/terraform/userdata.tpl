#! /bin/bash

# install SSM agent to allow access from the Session Manager web interface
mkdir /tmp/ssm
cd /tmp/ssm
wget -q https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb

# mount the EBS persistent volume
sudo apt update -y
sudo apt-get install awscli -y
EC2_INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`"
ECS_VOLUME_ID="`aws ec2 describe-volumes --region ca-central-1 --filters Name=tag:Name,Values="ResourceSpace FileStore" --query "Volumes[*].{ID:VolumeId}" --output text`"
aws ec2 attach-volume --volume-id $ECS_VOLUME_ID --instance-id $EC2_INSTANCE_ID --device "/dev/sdf" --region="ca-central-1"
sleep 2
sudo mount -t auto -v /dev/sdf /opt/bitnami/resourcespace/filestore

# download the files from our git repo to complete the ansible config
sudo -u bitnami mkdir -p /home/bitnami/repos
cd /home/bitnami/repos
sudo apt-get install git -y
#sudo apt-get install ansible -y
sudo -u bitnami git clone ${git_url} bcparks-dam
#cd /home/bitnami/repos/bcparks-dam/src/ansible

# mount the S3 bucket
sudo apt-get install s3fs -y
sudo mkdir /s3-backup
sudo s3fs bcparks-dam-dev-backup /s3-backup -o iam_role=BCParks-Dam-EC2-Role -o use_cache=/tmp -o allow_other -o uid=1000 -o gid=1 -o mp_umask=002  -o multireq_max=5 -o use_path_request_style -o url=https://s3-ca-central-1.amazonaws.com

