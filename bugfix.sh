#!/bin/bash
set -ex
for host in atl can mex nyc; do
	scp pubkey.chat "${host}.pubkey.chat:/var/www/cgi-bin/"
done
