#!/bin/bash
set -ex
for host in atl can mex nyc; do
	ssh "${host}.pubkey.chat" ln -sf /usr/local/bin/python3.11 /usr/local/bin/python3
	ssh "${host}.pubkey.chat" mkdir -p /var/www/htdocs/objects
	ssh "${host}.pubkey.chat" mkdir -p /var/www/htdocs/notices
	ssh "${host}.pubkey.chat" chown www:www /var/www/htdocs/objects
	ssh "${host}.pubkey.chat" chown www:www /var/www/htdocs/notices
	ssh "${host}.pubkey.chat" chmod 755 /var/www/htdocs/objects
	ssh "${host}.pubkey.chat" chmod 755 /var/www/htdocs/notices
	ssh "${host}.pubkey.chat" rcctl enable httpd
	ssh "${host}.pubkey.chat" rcctl enable slowcgi
	ssh "${host}.pubkey.chat" rcctl set slowcgi flags -v -p /
	scp profile.sh "${host}.pubkey.chat:~/.profile"
done
