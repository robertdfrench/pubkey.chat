#!/bin/bash
sudo yum update -y
sudo yum install -y \
	python3 \
	python3-boto3 \
	openssh

sudo mv service.py /usr/local/bin/service.py

sudo mv chat.service /etc/systemd/system/chat.service
sudo systemctl daemon-reload
sudo systemctl enable chat.service
sudo systemctl start chat.service

curl https://github.com/robertdfrench.keys >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
