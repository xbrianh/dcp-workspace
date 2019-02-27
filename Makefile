all: image

image:
	docker build -f workspace.Dockerfile -t xbrianh/workspace .

publish: image
	docker push xbrianh/workspace

prune:
	docker container prune -f
	docker image prune -f

.PHONY: docker prune
