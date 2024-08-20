include ../lib/common.mk
include ../lib/tf.mk

test: tf_lint #: Lint
	make -C oob test
	make -C image test

apply: ami oob terraform.tfstate #: Create AWS Resources

ami:
	make -C image ami

oob:
	make -C oob apply

clean: clean_build #: Clean up intermediate artifacts
	make -C image clean
