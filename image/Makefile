include ../common.mk

all: image

image:
	docker build -f $(DCP_WORKSPACE_IMAGE_FILE) -t $(DCP_WORKSPACE_IMAGE_NAME) .

key: 
	yes y | ssh-keygen -t rsa -C "dss-team@data.humancellatlas.org" -b 4096 -f key -N ''

publish: image
	docker push $(DCP_WORKSPACE_IMAGE_NAME)

.PHONY: image publish
