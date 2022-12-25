all: test
	cargo build --release

test: /usr/local/bin/cargo
	cargo test

/usr/local/bin/cargo:
	pkg_add rust
