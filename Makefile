include helpers/*.mk
include plugins.mk

BINARY_REPO := github.com/launchrctl/launchr
BINARY_URL := https://${BINARY_REPO}

ifeq ($(UNAME_P),unknown)
BINARY_NAME := launchr_${UNAME_S}_x86_64
else
BINARY_NAME := launchr_${UNAME_S}_${UNAME_P}
endif

LAUNCHR_BINARY_CHECKSUM_EXPECTED := $(shell curl -sL ${BINARY_URL}/releases/latest/download/checksums.txt | grep "${BINARY_NAME}" | awk '{print $$1}')
LAUNCHR_BINARY_RELEASE_VERSION := $(shell curl -s https://api.github.com/repos/launchrctl/launchr/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

TARGET_OSES := darwin linux windows
TARGET_ARCHES := amd64 arm64

TARGET_VERSION :=
empty  :=
space  := $(empty) $(empty)
comma  := ,
TARGET_PLUGINS := $(subst $(space),$(comma),$(PLUGIN_LIST))

BUILD_LOG_FILE := build.log

.DEFAULT_GOAL := help

.PHONY: binaries
## Build plasmactl binaries for all platforms
binaries: check provision build
	@echo "-- Build complete!"
	@echo "-- Artifacts:"
	@ls -lah plasmactl_*

.PHONY: check
## Various pre-run checks
check:
	@echo
	@echo "- Action: check"
	# Check if TARGET_VERSION is set
	$(if $(TARGET_VERSION),,$(error TARGET_VERSION is not set: You need to pass it as make command argument))
	# Check if TARGET_VERSION matches SemVer pattern
	$(if $(shell echo "$(TARGET_VERSION)" | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+.*$$'),,\
		$(error TARGET_VERSION does not match the SemVer pattern. Please provide a valid version.))
	@echo "- Done."
	@echo

.PHONY: provision
## Download launchr binary corresponding to current OS & Arch
provision:
	@echo
	@echo "- Action: provision"
	@echo "-- Writing config file for update plugin..."
	@printf "repository_url: 'https://github.com/plasmash/plasmactl/releases/download'\nbin_mask: '{{.URL}}/{{.Version}}/plasmactl_{{.OS}}_{{.Arch}}{{.Ext}}'\n" > plasmactl-update.yaml
	@echo "-- Getting latest launchr binary file (release: ${LAUNCHR_BINARY_RELEASE_VERSION}) compatible with your OS & Arch..."
	curl -O -L ${BINARY_URL}/releases/latest/download/${BINARY_NAME}
	@echo "-- Comparing checksums..."
	echo '${LAUNCHR_BINARY_CHECKSUM_EXPECTED} ${BINARY_NAME}' | sha256sum --check
	chmod +x ${BINARY_NAME}
	@echo "-- Building binary with update plugin..."
	./${BINARY_NAME} build --no-cache --timeout 500s -vvv --tag nethttpomithttp2 -p github.com/launchrctl/update@v1.1.3 -n plasmactl -o ${BINARY_NAME} --build-version ${LAUNCHR_BINARY_RELEASE_VERSION}
	@echo "-- Done."
	@echo

.PHONY: build
## Build plasmactl (launchr + plugins) binaries compatible with multiple OS & Arch
build:
	@echo "- Action: build"
	@echo "-- Building plasmactl (launchr + plugins) binaries compatible with multiple OS & Arch..."
	$(foreach TARGET_OS,$(TARGET_OSES), \
		$(eval EXTENSION :=) \
		$(if $(filter windows,$(TARGET_OS)), $(eval EXTENSION := .exe)) \
		$(foreach TARGET_ARCH,$(TARGET_ARCHES), \
			echo "Compiling artifact plasmactl_$(TARGET_OS)_$(TARGET_ARCH)$(EXTENSION)..." ; \
			GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) ./${BINARY_NAME} build --no-cache --timeout 500s -vvv --tag nethttpomithttp2 -p ${TARGET_PLUGINS} $(if ${LOCAL_PLUGIN_REPLACE},-r ${LOCAL_PLUGIN_REPLACE}) -n plasmactl -o "plasmactl_$(TARGET_OS)_$(TARGET_ARCH)$(EXTENSION)" --build-version ${TARGET_VERSION} 2>&1 | tee ${BUILD_LOG_FILE} ; \
		) \
	)
	@echo "-- Artifacts generated:"
	@ls -lah | grep plasmactl_
	@echo "-- Done."
	@echo

.PHONY: clean
## Clean build artifacts
clean:
	@echo "- Action: clean"
	rm -f plasmactl_* plasmactl launchr_* ${BUILD_LOG_FILE} plasmactl-update.yaml
	@echo "-- Done."
