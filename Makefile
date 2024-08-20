include lib/common.mk
include lib/venv.mk

deploy: test #: Deploy to production
	$(MAKE) -C infrastructure apply
	$(MAKE) -C website deploy

test: test_client test_infrastructure #: Run all tests

test_client: lint typecheck check #: Test the client code

test_infrastructure:
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

review_coverage: .venv/ready  #: Show coverage report in browser
	$(venv) pytest --cov=. --cov-report=html
	open htmlcov/index.html
