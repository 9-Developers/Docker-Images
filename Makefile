CONTAINER_TOOL ?= podman
REGISTRY ?= ghcr.io
OWNER ?= 9-developers
REPOSITORY ?= images
FREEBSD_VERSION ?= 15.1

IMAGE_PREFIX = $(REGISTRY)/$(OWNER)/$(REPOSITORY)
BASE_IMAGE = $(IMAGE_PREFIX)/freebsd-ci-base
NODE_IMAGE = $(IMAGE_PREFIX)/freebsd-ci-node
OPENJDK_IMAGE = $(IMAGE_PREFIX)/freebsd-ci-openjdk
RUST_IMAGE = $(IMAGE_PREFIX)/freebsd-ci-rust
SECURITY_IMAGE = $(IMAGE_PREFIX)/freebsd-ci-security

.PHONY: all help login build publish \
	build-base build-node build-openjdk build-rust build-security \
	push-base push-node push-openjdk push-rust push-security

all: build

help:
	@echo "FreeBSD CI image builder"
	@echo
	@echo "Targets:"
	@echo "  build       Build every image (base first)"
	@echo "  publish     Build and push every image"
	@echo "  login       Log in to GHCR using GHCR_USER and GHCR_TOKEN"
	@echo "  build-NAME  Build one image: base, node, openjdk, rust, security"
	@echo "  push-NAME   Build and push one image"
	@echo
	@echo "Configuration:"
	@echo "  CONTAINER_TOOL=$(CONTAINER_TOOL)"
	@echo "  IMAGE_PREFIX=$(IMAGE_PREFIX)"
	@echo "  FREEBSD_VERSION=$(FREEBSD_VERSION)"

login:
	@test -n "$$GHCR_USER" || { echo "GHCR_USER is required" >&2; exit 1; }
	@test -n "$$GHCR_TOKEN" || { echo "GHCR_TOKEN is required" >&2; exit 1; }
	@printf '%s' "$$GHCR_TOKEN" | $(CONTAINER_TOOL) login $(REGISTRY) --username "$$GHCR_USER" --password-stdin

# The child images use the freshly built local base image. With `make -j`, they
# build concurrently after build-base completes.
build: build-node build-openjdk build-rust build-security

build-base:
	@git_tag=git-$$(git rev-parse --short=12 HEAD); \
	$(CONTAINER_TOOL) build \
		--tag $(BASE_IMAGE):$(FREEBSD_VERSION) \
		--tag $(BASE_IMAGE):$$git_tag \
		ci/base

build-node: build-base
	@git_tag=git-$$(git rev-parse --short=12 HEAD); \
	$(CONTAINER_TOOL) build \
		--build-arg FREEBSD_CI_BASE=$(BASE_IMAGE):$(FREEBSD_VERSION) \
		--tag $(NODE_IMAGE):24 \
		--tag $(NODE_IMAGE):24-freebsd$(FREEBSD_VERSION) \
		--tag $(NODE_IMAGE):$$git_tag \
		ci/node/24

build-openjdk: build-base
	@git_tag=git-$$(git rev-parse --short=12 HEAD); \
	$(CONTAINER_TOOL) build \
		--build-arg FREEBSD_CI_BASE=$(BASE_IMAGE):$(FREEBSD_VERSION) \
		--tag $(OPENJDK_IMAGE):25 \
		--tag $(OPENJDK_IMAGE):25-freebsd$(FREEBSD_VERSION) \
		--tag $(OPENJDK_IMAGE):$$git_tag \
		ci/openjdk/25

build-rust: build-base
	@git_tag=git-$$(git rev-parse --short=12 HEAD); \
	$(CONTAINER_TOOL) build \
		--build-arg FREEBSD_CI_BASE=$(BASE_IMAGE):$(FREEBSD_VERSION) \
		--tag $(RUST_IMAGE):$(FREEBSD_VERSION) \
		--tag $(RUST_IMAGE):$$git_tag \
		ci/rust

build-security: build-base
	@git_tag=git-$$(git rev-parse --short=12 HEAD); \
	$(CONTAINER_TOOL) build \
		--build-arg FREEBSD_CI_BASE=$(BASE_IMAGE):$(FREEBSD_VERSION) \
		--tag $(SECURITY_IMAGE):$(FREEBSD_VERSION) \
		--tag $(SECURITY_IMAGE):$$git_tag \
		ci/security

publish: push-base push-node push-openjdk push-rust push-security

push-base: build-base
	@set -e; git_tag=git-$$(git rev-parse --short=12 HEAD); \
	$(CONTAINER_TOOL) push $(BASE_IMAGE):$(FREEBSD_VERSION); \
	$(CONTAINER_TOOL) push $(BASE_IMAGE):$$git_tag

push-node: build-node
	@set -e; git_tag=git-$$(git rev-parse --short=12 HEAD); \
	$(CONTAINER_TOOL) push $(NODE_IMAGE):24; \
	$(CONTAINER_TOOL) push $(NODE_IMAGE):24-freebsd$(FREEBSD_VERSION); \
	$(CONTAINER_TOOL) push $(NODE_IMAGE):$$git_tag

push-openjdk: build-openjdk
	@set -e; git_tag=git-$$(git rev-parse --short=12 HEAD); \
	$(CONTAINER_TOOL) push $(OPENJDK_IMAGE):25; \
	$(CONTAINER_TOOL) push $(OPENJDK_IMAGE):25-freebsd$(FREEBSD_VERSION); \
	$(CONTAINER_TOOL) push $(OPENJDK_IMAGE):$$git_tag

push-rust: build-rust
	@set -e; git_tag=git-$$(git rev-parse --short=12 HEAD); \
	$(CONTAINER_TOOL) push $(RUST_IMAGE):$(FREEBSD_VERSION); \
	$(CONTAINER_TOOL) push $(RUST_IMAGE):$$git_tag

push-security: build-security
	@set -e; git_tag=git-$$(git rev-parse --short=12 HEAD); \
	$(CONTAINER_TOOL) push $(SECURITY_IMAGE):$(FREEBSD_VERSION); \
	$(CONTAINER_TOOL) push $(SECURITY_IMAGE):$$git_tag
