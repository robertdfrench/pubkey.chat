include ../../common.mk

SOURCES = chat.service provisioner.sh build/pubkey.chat packer.pkr.hcl

test: #: Run a fake test
	@echo "okay!"

ami: build/ami_name.txt update_ami_cache #: Build the latest AMI
	make build/amis/`cat $<`

update_ami_cache: build/image_name_id_pairs.sh #: Get Latest AMIs from Amazon
	sh $<

build/amis/%: build/variables.pkrvars.hcl build/amis/.dir $(SOURCES)
	packer build -var-file=$< packer.pkr.hcl
	touch $@

build/image_name_id_pairs.sh: build/ec2_describe_images.json build/amis/.dir 
	cat $< | jq -r '.Images[] | ("echo " + .ImageId + " > build/amis/" + .Name)' > $@

build/ec2_describe_images.json: .venv/ready build/.dir
	$(venv) aws ec2 describe-images --owners self > $@

build/variables.pkrvars.hcl: build/ami_name.txt
	echo "ami_name = \"`cat $<`\"" > $@

build/ami_name.txt: $(SOURCES) build/.dir
	cat $(SOURCES) | shasum -a 256 | sed 's/  -//; s/^/chat-service-/' > $@

build/pubkey.chat: ../../pubkey.chat build/.dir
	cp $< $@

clean: clean_build #: Clean up intermediate artifacts
