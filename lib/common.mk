help: #: Print this help message
	@cat $(MAKEFILE_LIST) \
		| grep '#' \
		| grep ':' \
		| awk -F':' '{ OFS="\t"; print $$1, "-", $$3 }' \
		| column -s"	" -t \
		| sort

clean_build:
	rm -rf build

%/.dir:
	mkdir -p $*
	touch $@
