include ../lib/common.mk
include ../lib/tf.mk

test: tf_lint #: Lint
	make -C dns test

apply: ami oob terraform.tfstate #: Create AWS Resources

ami:
	make -C image ami

oob:
	make -C dns apply

clean: clean_build #: Clean up intermediate artifacts
	make -C image clean
