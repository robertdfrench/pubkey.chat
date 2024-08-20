include ../lib/common.mk
include ../lib/venv.mk

SOURCES=index.html social_media_preview.jpg

deploy: $(patsubst %, build/%.deploy, $(SOURCES))  #: Deploy changes to website

build/index.html.deploy: index.html build/.dir .venv/ready
	$(venv) aws s3 cp $< s3://objects-dot-pubkey-dot-chat/$<
	touch $@

build/%.deploy: % build/.dir .venv/ready
	$(venv) aws s3 cp $< s3://objects-dot-pubkey-dot-chat/assets/$<
	touch $@

test:
	@echo okay!
