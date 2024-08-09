include ../common.mk

test: #: Run a fake test
	@echo "okay!"

apply: main.tf build/tf_init #: Launch an instance
	make -C image ami
	terraform validate
	terraform apply -auto-approve

destroy: build/tf_init #: Destroy terraform infrastructure
	terraform destroy -auto-approve

build/tf_init: providers.tf build/.dir
	terraform init
	touch $@

clean: clean_build #: Clean up intermediate artifacts
	make -C image clean
