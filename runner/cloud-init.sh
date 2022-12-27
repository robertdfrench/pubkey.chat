#!/bin/bash
mkdir actions-runner && cd actions-runner
curl -o actions-runner-osx-x64-2.299.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.299.1/actions-runner-osx-x64-2.299.1.tar.gz
echo "b0128120f2bc48e5f24df513d77d1457ae845a692f60acf3feba63b8d01a8fdc actions-runner-osx-x64-2.299.1.tar.gz" | shasum -a 256 -c
tar xzf ./actions-runner-osx-x64-2.299.1.tar.gz
./config.sh --url https://github.com/robertdfrench/pubkey.chat --token TOKEN
