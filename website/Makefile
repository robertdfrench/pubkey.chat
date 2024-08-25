include ../lib/common.mk
include ../lib/venv.mk

SOURCES=index.html social_media_preview.jpg screengrab.gif

deploy: $(patsubst %, build/%.deploy, $(SOURCES))  #: Deploy changes to website

build/index.html.deploy: index.html build/.dir .venv/ready
	$(venv) aws s3 cp $< s3://objects-dot-pubkey-dot-chat/$<
	touch $@

build/%.deploy: % build/.dir .venv/ready
	$(venv) aws s3 cp $< s3://objects-dot-pubkey-dot-chat/assets/$<
	touch $@

test:
	@echo okay!

# We don't list any pre-requisites here because we want to keep screengrab.gif
# under version control. If a new screengrab movie is made, update this by hand.
rebuild_screengrab:  #: Update screengrab.gif you record a new screengrab movie
ifndef INPUT_MOVIE
	$(error Define INPUT_MOVIE to point to a quicktime file)
endif
	make build/.dir
	ffmpeg \
		-i $(INPUT_MOVIE) \
		-vf "fps=10,scale=640:-1:flags=lanczos" \
		-c:v gif \
		build/unoptimized.gif
	gifsicle -O3 build/unoptimized.gif -o screengrab.gif
