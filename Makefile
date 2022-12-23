all: \
	/etc/doas.conf \
	/etc/ssh/sshd_config \
	/usr/local/bin/akc \
	/usr/local/bin/readmail \
	/usr/local/bin/writemail \
	/usr/local/bin/invitemail

/etc/doas.conf: doas.conf
	install -m 644 -o root -g wheel doas.conf /etc/doas.conf

/etc/ssh/sshd_config: sshd_config
	install -m 644 -o root -g wheel sshd_config /etc/ssh/sshd_config
	rcctl restart sshd

/usr/local/bin/akc: akc
	install -m 755 -o root -g wheel akc /usr/local/bin/akc

/usr/local/bin/readmail: readmail
	install -m 755 -o root -g wheel readmail /usr/local/bin/readmail

/usr/local/bin/writemail: writemail
	install -m 755 -o root -g wheel writemail /usr/local/bin/writemail

/usr/local/bin/invitemail: invitemail
	install -m 755 -o root -g wheel invitemail /usr/local/bin/invitemail
