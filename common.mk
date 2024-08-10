venv=. .venv/bin/activate &&

help: #: Print this help message
	@cat $(MAKEFILE_LIST) \
		| grep '#' \
		| grep ':' \
		| awk -F':' '{ OFS="\t"; print $$1, "-", $$3 }' \
		| column -s"	" -t \
		| sort

freeze: .venv/ready #: Freeze the current requirements
	$(venv) pip freeze > dev-requirements.txt

.venv/ready: dev-requirements.txt .venv/upgrade
	$(venv) pip install -r dev-requirements.txt
	touch $@

.venv/upgrade: .venv/init
	$(venv) pip install --upgrade pip
	touch $@

.venv/init:
	python3 -m venv .venv
	touch $@

clean_build:
	rm -rf build .venv

%/.dir:
	mkdir -p $*
	touch $@
