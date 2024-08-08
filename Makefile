include common.mk

test: #: Run all tests
	$(MAKE) -C client test
	$(MAKE) -C service test

clean: #: Clean all subprojects
	$(MAKE) -C client clean
	$(MAKE) -C service clean
