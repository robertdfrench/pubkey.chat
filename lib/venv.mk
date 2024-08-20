venv=. .venv/bin/activate &&

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

clean_venv:
	rm -rf .venv
