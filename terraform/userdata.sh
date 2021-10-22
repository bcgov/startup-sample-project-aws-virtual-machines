#! /bin/bash
cd /home/ssm-user/
sudo yum update -y
sudo yum install -y libselinux-python
sudo amazon-linux-extras install ansible2 -y
sudo yum install git -y
git clone https://github.com/prabhukiran9999/ssp-vm-version.git /home/ssm-user/repos/
sudo yum install -y policycoreutils-python
cd /home/ssm-user/repos/playbook
export AWS_REGION=ca-central-1
ansible-playbook dev.yml
