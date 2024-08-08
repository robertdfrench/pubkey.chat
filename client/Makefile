include ../common.mk

test: .venv/ready #: Run client unit tests
	$(venv) pytest --cov=. --cov-fail-under=100

clean: clean_build #: Clean up test venv
