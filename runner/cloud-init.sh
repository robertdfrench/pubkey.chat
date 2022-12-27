#!/bin/bash
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
sudo -u ubuntu /bin/bash - << 'EOF'
set -ex
cd /home/ubuntu/actions-runner
nohup ./run.sh &
EOF
