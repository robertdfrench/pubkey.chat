include ../common.mk

deploy: index.html .venv/ready
	$(venv) aws s3 cp $< s3://objects-dot-pubkey-dot-chat/$<
