include ../common.mk

test: build/tf_init #: Run a fake test
	make -C dns test
	terraform fmt -diff
	terraform validate

apply: build/tf_init #: Create AWS Resources
	make -C image ami
	make -C dns apply
	terraform apply -auto-approve

plan: build/tf_init #: Review a plan before applying it
	terraform plan

destroy: build/tf_init #: Destroy terraform infrastructure
	terraform destroy -auto-approve

build/tf_init: providers.tf build/.dir
	terraform init
	touch $@

clean: clean_build #: Clean up intermediate artifacts
	make -C image clean
