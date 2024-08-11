#!/bin/bash
sudo yum update -y
sudo yum install -y \
	python3 \
	python3-boto3 \
	openssh

sudo mv pubkey.chat /usr/local/bin/pubkey.chat

sudo mv chat.service /etc/systemd/system/chat.service
sudo systemctl daemon-reload
sudo systemctl enable chat.service

curl --silent https://github.com/robertdfrench.keys >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
