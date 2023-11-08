#! /bin/bash

# install SSM agent to allow access from the Session Manager web interface
mkdir /tmp/ssm
cd /tmp/ssm
wget -q https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb

# download the files from our git repo to complete the ansible config
sudo -u bitnami mkdir -p /home/bitnami/repos
cd /home/bitnami/repos
sudo apt update -y
sudo apt-get install git -y
sudo apt-get install ansible -y
sudo -u bitnami git clone ${git_url} bcparks-dam
cd /home/bitnami/repos/bcparks-dam/src/ansible
# ansible-playbook playbook.yml -e "dynamodb_table_name=DB_NAME" -e "aws_region=${AWS_REGION}"
