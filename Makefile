all: \
	/etc/doas.conf \
	/etc/ssh/sshd_config \
	/usr/local/bin/pkc-keys \
	/usr/local/bin/pkc-read \
	/usr/local/bin/pkc-write \
	/usr/local/bin/pkc-invite \
	/usr/local/bin/pkc-shell

/etc/doas.conf: doas.conf
	install -m 644 -o root -g wheel doas.conf /etc/doas.conf

/etc/ssh/sshd_config: sshd_config
	install -m 644 -o root -g wheel sshd_config /etc/ssh/sshd_config
	rcctl restart sshd

/usr/local/bin/pkc-keys: pkc-keys
	install -m 755 -o root -g wheel pkc-keys /usr/local/bin/pkc-keys

/usr/local/bin/pkc-read: pkc-read
	install -m 755 -o root -g wheel pkc-read /usr/local/bin/pkc-read

/usr/local/bin/pkc-write: pkc-write
	install -m 755 -o root -g wheel pkc-write /usr/local/bin/pkc-write

/usr/local/bin/pkc-invite: pkc-invite
	install -m 755 -o root -g wheel pkc-invite /usr/local/bin/pkc-invite

/usr/local/bin/pkc-shell: pkc-shell
	install -m 755 -o root -g wheel pkc-shell /usr/local/bin/pkc-shell
