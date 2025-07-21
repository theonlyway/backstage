# Makefile for building Backstage Docker image (based on build.yml)

# VERSION is the tag for the image, default to 0.0.1 if not set
VERSION ?= 0.0.1
# REGISTRY and IMAGE_NAME can be overridden as needed
REGISTRY ?= ghcr.io
REPOSITORY_OWNER ?= $(shell echo $(USER) | tr '[:upper:]' '[:lower:]')
IMAGE_NAME ?= backstage
# Path to Dockerfile (adjust if needed)
DOCKERFILE ?= Dockerfile
DEBUG_DOCKERFILE ?= Dockerfile.debug
# Path to context (adjust if needed)
CONTEXT ?= .
# Full image name
FULL_IMAGE ?= $(REGISTRY)/$(REPOSITORY_OWNER)/$(IMAGE_NAME)
# Cache path for buildx
CACHE_PATH ?= $(FULL_IMAGE)/cache
# CACHE_TTL defines the time-to-live for cache layers in the registry.
# Default is 30 days. You can override this by setting CACHE_TTL (e.g., make CACHE_TTL=7d docker-build).
CACHE_TTL ?= 90d
# CONTAINER_TOOL defines the container tool to be used for building images.
# Be aware that the target commands are only tested with Docker which is
# scaffolded by default. However, you might want to replace it to use other
# tools. (i.e. podman)
CONTAINER_TOOL ?= docker
# PLATFORMS defines the target platforms for the manager image be built to provide support to multiple
# architectures. (i.e. make docker-buildx IMG=myregistry/mypoperator:0.0.1). To use this option you need to:
# - be able to use docker buildx. More info: https://docs.docker.com/build/buildx/
# - have enabled BuildKit. More info: https://docs.docker.com/develop/develop-images/build_enhancements/
# - be able to push the image to your registry (i.e. if you do not set a valid value via IMG=<myregistry/image:<tag>> then the export will fail)
# To adequately provide solutions that are compatible with multiple platforms, you should consider using this option.
#PLATFORMS ?= linux/arm64,linux/amd64,linux/s390x,linux/ppc64le
PLATFORMS ?= linux/amd64
.PHONY: docker-build
## Build the Backstage Docker image using buildx and cache
docker-build:
	# copy existing Dockerfile and insert --platform=${BUILDPLATFORM} into Dockerfile.cross, and preserve the original Dockerfile
	sed -e '1 s/\(^FROM\)/FROM --platform=\$$\{BUILDPLATFORM\}/; t' -e ' 1,// s//FROM --platform=\$$\{BUILDPLATFORM\}/' $(DOCKERFILE) > Dockerfile.cross
	- $(CONTAINER_TOOL) buildx create --name builder
	$(CONTAINER_TOOL) buildx use builder
	$(CONTAINER_TOOL) buildx build --push \
		--platform=$(PLATFORMS) \
		--cache-from=type=registry,ref=$(CACHE_PATH):cache \
		--cache-to=type=registry,ref=$(CACHE_PATH):cache,mode=max,ttl=$(CACHE_TTL) \
		--tag $(FULL_IMAGE):$(VERSION) \
		--tag $(FULL_IMAGE):latest \
		-f Dockerfile.cross $(CONTEXT)
	- $(CONTAINER_TOOL) buildx rm builder
	rm Dockerfile.cross

.PHONY: docker-build-debug
## Build the debug Backstage Docker image using buildx and cache
docker-build-debug:
	# copy existing Dockerfile and insert --platform=${BUILDPLATFORM} into Dockerfile.cross, and preserve the original Dockerfile
	sed -e '1 s/\(^FROM\)/FROM --platform=\$$\{BUILDPLATFORM\}/; t' -e ' 1,// s//FROM --platform=\$$\{BUILDPLATFORM\}/' $(DEBUG_DOCKERFILE) > Dockerfile.cross
	- $(CONTAINER_TOOL) buildx create --name builder
	$(CONTAINER_TOOL) buildx use builder
	$(CONTAINER_TOOL) buildx build --push \
		--platform=$(PLATFORMS) \
		--cache-from=type=registry,ref=$(CACHE_PATH):cache \
		--cache-to=type=registry,ref=$(CACHE_PATH):cache,mode=max,ttl=$(CACHE_TTL) \
		--tag $(FULL_IMAGE):$(VERSION)-debug \
		--tag $(FULL_IMAGE):latest-debug \
		-f Dockerfile.cross $(CONTEXT)
	- $(CONTAINER_TOOL) buildx rm builder
	rm Dockerfile.cross

.PHONY: build-backend
## Build the backend and create required tarballs for Docker image
build-backend:
	yarn install --immutable
	yarn tsc
	yarn build:backend

.PHONY: help
help: ## Show this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
