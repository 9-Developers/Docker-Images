CONTAINER_TOOL ?= podman
REGISTRY_TOOL ?= skopeo
REGISTRY ?= git.9dev.tech
OWNER ?= 9-developers
FREEBSD_VERSION ?= 15.1
PKG_QUARTER ?= 2026q4
IMAGE_REVISION ?= 3
CONFIRMED_PKG_QUARTER ?=

export CONTAINER_TOOL REGISTRY_TOOL REGISTRY OWNER FREEBSD_VERSION PKG_QUARTER IMAGE_REVISION CONFIRMED_PKG_QUARTER
BOOKWORM_NODE_MAJOR ?= 24
BOOKWORM_REVISION ?= 3
export BOOKWORM_NODE_MAJOR BOOKWORM_REVISION
FREEBSD_IMAGES = base dotnet go node odin openjdk postgres rust security
IMAGES = $(FREEBSD_IMAGES) railway

.PHONY: all help login check-tools build publish publish-existing $(addprefix build-,$(IMAGES)) $(addprefix push-,$(IMAGES))
all: build
help:
	@echo "Use gmake on FreeBSD (GNU make required)."
	@echo "build / publish / publish-existing operate on the FreeBSD release"
	@echo "build-NAME: build one image (railway builds directly from Debian-based Node)"
	@echo "publish: build all images, publish release tags, then moving aliases"
	@echo "publish-existing: publish already-built local release images without rebuilding"
	@echo "check-tools: verify Podman and Skopeo access"
	@echo "push-NAME: build and publish one image"
	@echo "login: authenticate using REGISTRY_USER and REGISTRY_TOKEN"
	@echo "Images: $(IMAGES)"
	@echo "Release: freebsd$(FREEBSD_VERSION)-$(PKG_QUARTER)-r$(IMAGE_REVISION)"
	@echo "Set CONFIRMED_PKG_QUARTER=$(PKG_QUARTER) after verifying the public package branch."
login:
	@sh ci/images.sh login
check-tools:
	@sh ci/images.sh check-tools
build: $(addprefix build-,$(FREEBSD_IMAGES))
build-railway:
	@sh ci/images.sh build railway
build-base:
	@sh ci/images.sh build base
$(addprefix build-,$(filter-out base,$(FREEBSD_IMAGES))): build-base
	@sh ci/images.sh build $(@:build-%=%)
publish: build
	@sh ci/images.sh publish $(FREEBSD_IMAGES)
publish-existing: check-tools
	@sh ci/images.sh publish $(FREEBSD_IMAGES)
$(addprefix push-,$(IMAGES)): push-%: build-%
	@sh ci/images.sh publish $*
