include common.mk

test: #: Run all tests
	$(MAKE) -C client test
