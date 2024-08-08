venv=. .venv/bin/activate &&

help: #: Print this help message
	@cat $(MAKEFILE_LIST) \
		| grep '#' \
		| grep ':' \
		| awk -F':' '{ OFS="\t"; print $$1, "-", $$3 }' \
		| column -s"	" -t

freeze: .venv/ready #: Freeze the current requirements
	$(venv) pip freeze > requirements.txt

.venv/ready: requirements.txt .venv/upgrade
	$(venv) pip install -r requirements.txt
	touch $@

.venv/upgrade: .venv/init
	$(venv) pip install --upgrade pip
	touch $@

.venv/init:
	python3 -m venv .venv
	touch $@
