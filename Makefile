CONTAINER_TOOL ?= podman
REGISTRY ?= git.9dev.tech
OWNER ?= 9-developers
FREEBSD_VERSION ?= 15.1
PKG_QUARTER ?= 2026q4
IMAGE_REVISION ?= 1
CONFIRMED_PKG_QUARTER ?=

export CONTAINER_TOOL REGISTRY OWNER FREEBSD_VERSION PKG_QUARTER IMAGE_REVISION CONFIRMED_PKG_QUARTER
IMAGES = base node openjdk rust security odin

.PHONY: all help login build publish $(addprefix build-,$(IMAGES)) $(addprefix push-,$(IMAGES))
all: build
help:
	@echo "Use gmake on FreeBSD (GNU make required)."
	@echo "build / build-NAME: refresh and build images, base first"
	@echo "publish: build all images, publish release tags, then moving aliases"
	@echo "push-NAME: build and publish one image"
	@echo "login: authenticate using REGISTRY_USER and REGISTRY_TOKEN"
	@echo "Images: $(IMAGES)"
	@echo "Release: freebsd$(FREEBSD_VERSION)-$(PKG_QUARTER)-r$(IMAGE_REVISION)"
	@echo "Set CONFIRMED_PKG_QUARTER=$(PKG_QUARTER) after verifying the public package branch."
login:
	@sh ci/images.sh login
build: $(addprefix build-,$(IMAGES))
build-base:
	@sh ci/images.sh build base
$(addprefix build-,node openjdk rust security odin): build-base
	@sh ci/images.sh build $(@:build-%=%)
publish: build
	@sh ci/images.sh publish $(IMAGES)
$(addprefix push-,$(IMAGES)): push-%: build-%
	@sh ci/images.sh publish $*
