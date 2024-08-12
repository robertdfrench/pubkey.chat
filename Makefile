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

review_coverage: .venv/ready  #: Show coverage report in browser
	$(venv) pytest --cov=. --cov-report=html
	open htmlcov/index.html
