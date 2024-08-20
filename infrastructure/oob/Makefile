include ../../lib/common.mk
include ../../lib/tf.mk

test: tf_lint #: Validate terraform config

apply: terraform.tfstate build/nameservers #: Create AWS Resources

build/nameservers: build/.dir terraform.tfstate
	@echo Run 'touch build/nameservers' if you have added
	@echo all of the zone\'s nameservers at the registrar.
	@exit 1

clean: clean_build #: Clean up intermediate artifacts
