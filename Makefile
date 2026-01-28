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

TARGET_OSES := Darwin Linux Windows
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
binaries: check provision build legacy-naming
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
	@printf "repository_url: 'https://github.com/plasmash/plasmactl/releases/download'\nbin_mask: '{{.URL}}/{{.Version}}/plasmactl_{{.OS}}_{{.Arch}}{{.Ext}}'\n" > launchr-update.yaml
	@echo "-- Getting latest launchr binary file (release: ${LAUNCHR_BINARY_RELEASE_VERSION}) compatible with your OS & Arch..."
	curl -O -L ${BINARY_URL}/releases/latest/download/${BINARY_NAME}
	@echo "-- Comparing checksums..."
	echo '${LAUNCHR_BINARY_CHECKSUM_EXPECTED} ${BINARY_NAME}' | sha256sum --check
	chmod +x ${BINARY_NAME}
	@echo "-- Building binary with update plugin..."
	./${BINARY_NAME} build --no-cache --timeout 500s -vvv --tag nethttpomithttp2 -p github.com/launchrctl/update@v1.1.2 -n plasmactl -o ${BINARY_NAME} --build-version ${LAUNCHR_BINARY_RELEASE_VERSION}
	@echo "-- Done."
	@echo

.PHONY: build
## Build plasmactl (launchr + plugins) binaries compatible with multiple OS & Arch
build:
	@echo "- Action: build"
	@echo "-- Building plasmactl (launchr + plugins) binaries compatible with multiple OS & Arch..."
	$(foreach TARGET_OS,$(TARGET_OSES), \
		$(eval GOOS := $(shell echo $(TARGET_OS) | tr '[:upper:]' '[:lower:]')) \
		$(eval EXTENSION :=) \
		$(if $(filter Windows,$(TARGET_OS)), $(eval EXTENSION := .exe)) \
		$(foreach TARGET_ARCH,$(TARGET_ARCHES), \
			$(eval ARCH_NAME := $(if $(filter amd64,$(TARGET_ARCH)),x86_64,$(if $(filter arm64,$(TARGET_ARCH)),arm64,$(TARGET_ARCH)))) \
			echo "Compiling artifact plasmactl_${TARGET_OS}_${ARCH_NAME}${EXTENSION}..." ; \
			GOOS=$(GOOS) GOARCH=$(TARGET_ARCH) ./${BINARY_NAME} build --no-cache --timeout 500s -vvv --tag nethttpomithttp2 -p ${TARGET_PLUGINS} $(if ${LOCAL_PLUGIN_REPLACE},-r ${LOCAL_PLUGIN_REPLACE}) -n plasmactl -o "plasmactl_${TARGET_OS}_${ARCH_NAME}${EXTENSION}" --build-version ${TARGET_VERSION} 2>&1 | tee ${BUILD_LOG_FILE} ; \
		) \
	)
	@echo "-- Artifacts generated:"
	@ls -lah | grep plasmactl_
	@echo "-- Done."
	@echo

SRC_BINS := \
  plasmactl_Darwin_arm64       \
  plasmactl_Darwin_x86_64      \
  plasmactl_Linux_arm64        \
  plasmactl_Linux_x86_64       \
  plasmactl_Windows_arm64.exe  \
  plasmactl_Windows_x86_64.exe
.PHONY: legacy-naming
legacy-naming: $(SRC_BINS)
	@echo "-- Also creating binaries with old backward-compatible naming:"
	@for f in $(SRC_BINS); do \
	  dst=$$(echo "$$f" | tr '[:upper:]' '[:lower:]'); \
	  if echo "$$dst" | grep -q 'x86_64'; then \
	    dst=$$(echo "$$dst" | sed 's/x86_64/amd64/'); \
	  fi; \
	  echo "Copying $$f → $$dst"; \
	  cp "$$f" "$$dst"; \
	done
	@echo "-- Done."
	@echo

.PHONY: clean
## Clean build artifacts
clean:
	@echo "- Action: clean"
	rm -f plasmactl_* plasmactl launchr_* ${BUILD_LOG_FILE} launchr-update.yaml
	@echo "-- Done."
