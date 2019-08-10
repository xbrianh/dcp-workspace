include ../common.mk

all: image

image:
	docker build -f image.Dockerfile -t $(DCP_WORKSPACE_IMAGE_NAME) .

publish: image
	docker push $(DCP_WORKSPACE_IMAGE_NAME)

prune:
	docker container prune -f
	docker image prune -f

.PHONY: docker prune
