include ../common.mk

test: #: Run a fake test
	@echo "okay!"

update_ami_cache: build/image_name_id_pairs.sh #: Get Latest AMIs from Amazon
	sh $<

build/image_name_id_pairs.sh: build/amis/.dir build/ec2_describe_images.json
	cat $< | jq -r '.Images[] | ("echo " + .ImageId + " > build/amis/" + .Name)' > $@

build/ec2_describe_images.json: .venv/ready build/.dir
	$(venv) aws ec2 describe-images --owners self > $@

clean: clean_build #: Clean up intermediate artifacts
