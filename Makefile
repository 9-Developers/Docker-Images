CONTAINER_TOOL ?= podman
REGISTRY_TOOL ?= skopeo
REGISTRY ?= git.9dev.tech
OWNER ?= 9-developers
FREEBSD_VERSION ?= 15.1
PKG_QUARTER ?= 2026q4
BASE_REVISION ?= 3
DOTNET_REVISION ?= 3
GO_REVISION ?= 3
NODE_REVISION ?= 3
ODIN_REVISION ?= 3
OPENJDK_REVISION ?= 3
POSTGRES_REVISION ?= 3
RUST_REVISION ?= 4
SECURITY_REVISION ?= 3
CONFIRMED_PKG_QUARTER ?=

export CONTAINER_TOOL REGISTRY_TOOL REGISTRY OWNER FREEBSD_VERSION PKG_QUARTER CONFIRMED_PKG_QUARTER
export BASE_REVISION DOTNET_REVISION GO_REVISION NODE_REVISION ODIN_REVISION OPENJDK_REVISION POSTGRES_REVISION RUST_REVISION SECURITY_REVISION
BOOKWORM_NODE_MAJOR ?= 24
BOOKWORM_REVISION ?= 6
export BOOKWORM_NODE_MAJOR BOOKWORM_REVISION
FREEBSD_IMAGES = base dotnet go node odin openjdk postgres rust security
IMAGES = $(FREEBSD_IMAGES) railway

.PHONY: all help railway-tag login check-tools build pull-base publish publish-existing $(addprefix tag-,$(IMAGES)) $(addprefix build-,$(IMAGES)) $(addprefix push-,$(IMAGES))
all: build
help:
	@echo "Use gmake on FreeBSD (GNU make required)."
	@echo "build / publish / publish-existing operate on the FreeBSD release"
	@echo "build-NAME: build one image (railway builds directly from Debian-based Node)"
	@echo "railway-tag: print the configured Railway release tag"
	@echo "publish: build and publish missing FreeBSD release tags and their aliases"
	@echo "publish-existing: publish missing FreeBSD tags from already-built local images"
	@echo "check-tools: verify Podman and Skopeo access"
	@echo "push-NAME: build and publish one image"
	@echo "login: authenticate using REGISTRY_USER and REGISTRY_TOKEN"
	@echo "Images: $(IMAGES)"
	@echo "tag-NAME: print the configured release tag for one image"
	@echo "Set CONFIRMED_PKG_QUARTER=$(PKG_QUARTER) after verifying the public package branch."
railway-tag: tag-railway
$(addprefix tag-,$(IMAGES)): tag-%:
	@sh ci/images.sh tag $*
login:
	@sh ci/images.sh login
check-tools:
	@sh ci/images.sh check-tools
build:
	@$(MAKE) BASE_TARGET=build-base $(addprefix build-,$(FREEBSD_IMAGES))
BASE_TARGET = pull-base
pull-base:
	@sh ci/images.sh pull-base
build-railway:
	@sh ci/images.sh build railway
build-base:
	@sh ci/images.sh build base
$(addprefix build-,$(filter-out base,$(FREEBSD_IMAGES))): $(BASE_TARGET)
	@sh ci/images.sh build $(@:build-%=%)
publish:
	@set -eu; missing=$$(sh ci/images.sh missing $(FREEBSD_IMAGES)); \
	test -n "$$missing" || exit 0; \
	base_target=pull-base; \
	for image in $$missing; do \
		if test "$$image" = base; then base_target=build-base; fi; \
	done; \
	$(MAKE) BASE_TARGET=$$base_target PENDING_IMAGES="$$missing" publish-selected
.PHONY: publish-selected
publish-selected: $(addprefix build-,$(PENDING_IMAGES))
	@sh ci/images.sh publish $(PENDING_IMAGES)
publish-existing: check-tools
	@set -eu; missing=$$(sh ci/images.sh missing $(FREEBSD_IMAGES)); \
	test -n "$$missing" || exit 0; sh ci/images.sh publish $$missing
$(addprefix push-,$(IMAGES)): push-%: build-%
	@sh ci/images.sh publish $*
