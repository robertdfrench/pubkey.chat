include common.mk

deploy: test #: Deploy to production
	$(MAKE) -C infrastructure apply

test: lint typecheck check #: Run all tests
	$(MAKE) -C infrastructure test

clean: build_clean #: Clean all intermediate cruft
	rm -rf .venv
	$(MAKE) -C infrastructure clean

check: .venv/ready
	$(venv) pytest --cov=. --cov-fail-under=100

lint: .venv/ready
	$(venv) flake8 pubkey.chat tests/test_wmap.py

typecheck: .venv/ready
	$(venv) mypy pubkey.chat
