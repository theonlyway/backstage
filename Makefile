# Makefile for building Backstage Docker image (based on build.yml)

# VERSION is the tag for the image, default to 0.0.1 if not set
VERSION ?= 0.0.1
# REGISTRY and IMAGE_NAME can be overridden as needed
REGISTRY ?= ghcr.io
REPOSITORY_OWNER ?= $(shell echo $(USER) | tr '[:upper:]' '[:lower:]')
IMAGE_NAME ?= backstage
# Path to Dockerfile (adjust if needed)
DOCKERFILE ?= packages/backend/Dockerfile
# Path to context (adjust if needed)
CONTEXT ?= .
# Cache path for buildx
CACHE_PATH ?= $(REGISTRY)/$(REPOSITORY_OWNER)/cache
# Full image name
FULL_IMAGE ?= $(REGISTRY)/$(REPOSITORY_OWNER)/$(IMAGE_NAME)

.PHONY: docker-build
## Build the Backstage Docker image using buildx and cache

docker-build:
	docker buildx build \
	  --cache-from=type=local,src=$(CACHE_PATH) \
	  --cache-to=type=local,dest=$(CACHE_PATH),mode=max,ttl=720h \
	  -t $(FULL_IMAGE):$(VERSION) \
	  -f $(DOCKERFILE) \
	  $(CONTEXT)

.PHONY: docker-push
## Push the Backstage Docker image to the registry
docker-push:
	docker push $(FULL_IMAGE):$(VERSION)

.PHONY: help
help: ## Show this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
