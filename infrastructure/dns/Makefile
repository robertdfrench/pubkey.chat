include ../../common.mk

test: #: Run a fake test
	@echo "okay!"

apply: build/nameservers #: Create AWS Resources

plan: build/tf_init #: Review a plan before applying it
	terraform plan

destroy: build/tf_init #: Destroy terraform infrastructure
	terraform destroy

build/tf_init: providers.tf build/.dir
	terraform init
	touch $@

build/zone: build/tf_init
	terraform apply -auto-approve
	touch $@

build/nameservers: build/zone
	@echo Run 'touch build/nameservers' if you have added
	@echo all of the zone\'s nameservers at the registrar.
	@exit 1

clean: clean_build #: Clean up intermediate artifacts
