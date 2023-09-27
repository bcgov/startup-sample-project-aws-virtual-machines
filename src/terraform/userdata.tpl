#! /bin/bash

sudo -u ec2-user mkdir -p /home/ec2-user/repos
cd /home/ec2-user/repos
sudo yum update -y
sudo yum install -y libselinux-python policycoreutils-python git
sudo amazon-linux-extras install ansible2 -y
sudo -u ec2-user git clone -b ${branch} ${git_url} backend
git checkout ${sha}
cd /home/ec2-user/repos/backend/src/ansible
ansible-playbook playbook.yml -e "dynamodb_table_name=${DB_NAME}" -e "aws_region=${AWS_REGION}"
