build/webhook: Cargo.toml src/ build/.dir
	rsync --rsync-path=/usr/bin/openrsync -r . root@build.pubkey.chat:webhook/
	ssh root@build.pubkey.chat make -C webhook -f remote.mk all
	scp root@build.pubkey.chat:~/webhook/target/release/webhook build/webhook

build/.dir:
	mkdir -p build
	touch $@

clean:
	rm -rf build
