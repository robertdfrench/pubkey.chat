all: build/os_id.txt build/packer.init config.pkr.hcl
	packer build -var "vultr_os_id=`cat $<`" config.pkr.hcl

build/packer.init: config.pkr.hcl build/.dir
	packer init config.pkr.hcl
	touch build/packer.init

build/os_id.txt: build/images.json
	jq '.os[] | select(.name == "OpenBSD 7.2 x64").id' $< > $@

build/images.json: build/.dir
	curl "https://api.vultr.com/v2/os" > $@

build/.dir:
	mkdir -p build
	touch $@

clean:
	rm -rf build
