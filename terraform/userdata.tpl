#! /bin/bash
cd /home/ssm-user/
sudo yum update -y
sudo yum install -y libselinux-python
sudo amazon-linux-extras install ansible2 -y
sudo yum install git -y
sudo git clone ${git_url} /home/ssm-user/repos/
git checkout ${sha}
sudo yum install -y policycoreutils-python
cd /home/ssm-user/repos/playbook
export AWS_REGION=ca-central-1
export bucketName=${bucketName}
export DB_NAME=${DB_NAME}
ansible-playbook dev.yml
