include ../common.mk

test: #: Run a fake test
	@echo "okay!"

apply: build/tf_init #: Create AWS Resources
	make -C image ami
	terraform validate
	terraform apply -auto-approve

plan: build/tf_init #: Review a plan before applying it
	terraform validate
	terraform plan

destroy: build/tf_init #: Destroy terraform infrastructure
	terraform destroy -auto-approve

build/tf_init: providers.tf build/.dir
	terraform init
	touch $@

clean: clean_build #: Clean up intermediate artifacts
	make -C image clean
