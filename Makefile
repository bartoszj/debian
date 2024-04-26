.PHONY: build

build:
	docker build -t bartoszj/debian . --progress plain
# 	docker build --platform linux/amd64 -t bartoszj/debian . --progress plain
# 	docker build --platform linux/arm64 -t bartoszj/debian . --progress plain

# docker buildx create --name mybuilder --bootstrap --use
buildx:
# 	docker buildx build --platform linux/arm64 -t bartoszj/debian . --push --progress plain
	docker buildx build --platform linux/amd64,linux/arm64 -t bartoszj/debian . --progress plain
# 	docker buildx build --platform linux/amd64,linux/arm64 -t bartoszj/debian . --push --progress plain
