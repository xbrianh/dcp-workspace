include common.mk

all: image

image:
	make -C image

publish: image
	make -C image publish

prune:
	docker container prune -f
	docker image prune -f

.PHONY: image publish prune
