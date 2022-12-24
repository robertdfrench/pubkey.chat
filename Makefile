all: build/image_description.txt config.json build/tfinit
	terraform apply \
		-var "vultr_api_key=${VULTR_API_KEY}" \
		-var "image_description=`cat build/image_description.txt`" \
		-var "vultr_plan_id=`jq -r '.vultr.plan' config.json`"

build/tfinit: init.tf build/.dir
	terraform init
	touch $@

build/image_description.txt: build/vultr_os_id.txt build/packer.init \
	config.pkr.hcl config.json
	image_description=`date "+pubkey.chat-%s"` \
		&& packer build \
			-var "vultr_os_id=`cat build/vultr_os_id.txt`" \
			-var "image_description=$${image_description}" \
			-var "vultr_plan_id=`jq -r '.vultr.plan' config.json`" \
			-var "vultr_region_id=`jq -r '.vultr.principal_region' config.json`" \
			config.pkr.hcl \
		&& echo "$${image_description}" > $@

build/packer.init: config.pkr.hcl build/.dir
	packer init config.pkr.hcl
	touch build/packer.init

build/vultr_os_id.txt: build/images.json config.json
	jq -r \
		--arg os "`jq -r '.vultr.os' config.json`" \
		'.os[] | select(.name == $$os) | .id' \
		build/images.json > $@

build/images.json: build/.dir
	curl "https://api.vultr.com/v2/os" > $@

build/.dir:
	mkdir -p build
	touch $@

clean:
	rm -rf build
