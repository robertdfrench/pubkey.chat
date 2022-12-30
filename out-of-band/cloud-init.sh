#!/bin/bash
set -e -o pipefail

# Prevent password login with root
sudo passwd -l root

# Install Hashicorp Repo
apt-get update && apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg \
	| gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring \
	--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
	--fingerprint \
	| grep "E8A0 32E0 94D8 EB4E A189  D270 DA41 8C88 A321 9F7B"
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
	| tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt-get install -y terraform packer

# Install Actions Runner
sudo -u ubuntu /bin/bash - << 'EOF'
set -ex
cd /home/ubuntu
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.299.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.299.1/actions-runner-linux-x64-2.299.1.tar.gz
echo "147c14700c6cb997421b9a239c012197f11ea9854cd901ee88ead6fe73a72c74  actions-runner-linux-x64-2.299.1.tar.gz" > checksum
shasum -a 256 -c checksum
tar xzf ./actions-runner-linux-x64-2.299.1.tar.gz
./config.sh --unattended \
	--url https://github.com/robertdfrench/pubkey.chat \
	--token TOKEN \
	--replace --name runner.invalid \
	--labels runner.invalid
EOF

# Install Actions Service
cd /home/ubuntu/actions-runner
./svc.sh install ubuntu
./svc.sh start
