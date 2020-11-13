.PHONY: build

build:
	DOCKER_BUILDKIT=1 docker build -t d .

buildx:
	docker buildx build --platform linux/amd64,linux/arm64 -t dd .
