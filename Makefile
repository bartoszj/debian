.PHONY: build

build:
	DOCKER_BUILDKIT=1 docker build -t d . --progress plain

buildx:
	# docker buildx build --platform linux/amd64,linux/arm64 -t dd . --progress plain
	docker buildx build --platform linux/arm64 -t bartoszj/debian . --push --progress plain
	# docker buildx build --platform linux/amd64,linux/arm64 -t bartoszj/debian . --push --progress plain
