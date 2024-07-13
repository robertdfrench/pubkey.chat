#!/bin/bash
set -ex
for host in atl can mex nyc; do
	scp pubkey.chat "${host}.pubkey.chat:/var/www/cgi-bin/"
	scp httpd.conf "${host}.pubkey.chat:/etc/"
	scp "${host}.fac" "${host}.pubkey.chat:/var/www/facades.txt"
	ssh "${host}.pubkey.chat" rcctl restart httpd
	ssh "${host}.pubkey.chat" rcctl restart slowcgi
done
