include helpers/*.mk
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
TARGET_ARCHES := amd64 arm64 386
TARGET_VERSION :=
TARGET_PLUGINS := github.com/launchrctl/compose@v0.9.0,github.com/launchrctl/keyring@v0.2.3,github.com/launchrctl/launchr@v0.13.0,github.com/launchrctl/web@v0.4.0,github.com/skilld-labs/plasmactl-bump@v1.8.0,github.com/skilld-labs/plasmactl-dependencies@v0.2.0,github.com/skilld-labs/plasmactl-meta@v0.7.0,github.com/skilld-labs/plasmactl-package@v1.1.0,github.com/skilld-labs/plasmactl-publish@v1.3.2,github.com/skilld-labs/plasmactl-update@v0.2.2
PLASMACTL_ARTIFACT_REPOSITORY_URL := repositories.skilld.cloud
PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME := pla-plasmactl-raw
PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME := pla-plasmactl
PLASMACTL_BINARY_NAME := plasmactl_${UNAME_S}_${UNAME_P}
BUILD_LOG_FILE := build.log
BUILD_LOG_FILTER := "^go: added github.com/launchrctl/\|^go: added github.com/skilld-labs/"
BUILD_LOG_STRING_TR := $(shell echo "sed 's|^go: added ||g' | sed 's|.*github.com/||g' | sed 's|^|plugin |g' | sed 's|/| |g'")
STABLE_RELEASE_FILE_NAME := stable_release
REMOTE_STABLE_RELEASE := $(shell echo "Deferred evaluation")

xx:
	@echo "SYSTEM_OS: ${SYSTEM_OS}"
	@echo "SYSTEM_PROCESSOR: ${SYSTEM_PROCESSOR}"
	@echo "UNAME_S: ${UNAME_S}"
	@echo "UNAME_P: ${UNAME_P}"
	@echo "TARGET_VERSION: $(TARGET_VERSION)"
	@echo "TARGET_PLUGINS: $(TARGET_PLUGINS)"
	@echo "BUILD_LOG_FILTER: ${BUILD_LOG_FILTER}"
	@echo "BUILD_LOG_STRING_TR: ${BUILD_LOG_STRING_TR}"


.DEFAULT_GOAL := help

evaluate_remote_stable_release:
	$(eval REMOTE_STABLE_RELEASE := $(shell curl -kL --keepalive-time 30 --retry 20 -s --user '${PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME}:${PLASMACTL_ARTIFACT_REPOSITORY_USER_PW}' https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/repository/${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}/${STABLE_RELEASE_FILE_NAME} --fail))

.PHONY: binaries
## Sequentially: check provision build push clean
binaries: xx check provision build push pin validate clean


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
	@echo "-- Getting latest launchr binary file (release: ${LAUNCHR_BINARY_RELEASE_VERSION}) compatible with your OS & Arch..."
	curl -O -L ${BINARY_URL}/releases/latest/download/${BINARY_NAME} # TODO: Get sources and compile launchr_Linux_x86_64 binary instead of getting binary that may not be available
	@echo "-- Comparing checksums..."
	echo '${LAUNCHR_BINARY_CHECKSUM_EXPECTED} ${BINARY_NAME}' | sha256sum --check
	chmod +x ${BINARY_NAME}
	@echo "-- Done."
	@echo

.PHONY: build
## Build plasmactl (launchr + plugins) binaries compatible with multiple OS & Arch
build:
	@echo "- Action: build"
	@echo "-- Building plasmactl (launchr + plugins) binaries compatible with multiple OS & Arch..."
	$(foreach TARGET_OS,$(TARGET_OSES), \
		$(if $(filter windows,$(TARGET_OS)), $(eval EXTENSION := .exe)) \
		$(foreach TARGET_ARCH,$(TARGET_ARCHES), \
			echo "Compiling artifact plasmactl_${TARGET_OS}_${TARGET_ARCH}${EXTENSION}..." ; \
			GOOS=${TARGET_OS} GOARCH=${TARGET_ARCH} ./${BINARY_NAME} build -vvv -p ${TARGET_PLUGINS} -n plasmactl -o plasmactl_${TARGET_OS}_${TARGET_ARCH}${EXTENSION} --build-version ${TARGET_VERSION} 2>&1 | tee ${BUILD_LOG_FILE} ; \
		) \
	)
	@echo "-- Artifacts generated:"
	@ls -lah | grep plasmactl_
	@grep ${BUILD_LOG_FILTER} $(BUILD_LOG_FILE) | ${BUILD_LOG_STRING_TR} | while IFS= read -r line; do \
		touch "$${line}"; \
	done
	@echo "-- Done."
	@echo

.PHONY: push
## Upload plasmactl binaries artifacts to Nexus repository
push:
	@echo "- Action: push"
	@echo "-- Pushing platmactl binaries to https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/#browse/browse:${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}..."
	$(if $(PLASMACTL_ARTIFACT_REPOSITORY_USER_PW),,$(error PLASMACTL_ARTIFACT_REPOSITORY_USER_PW is not set: You need to pass it as make command argument))
	$(eval ARTIFACT_BINARIES = $(shell ls plasmactl_*))
	$(if $(ARTIFACT_BINARIES),,$(error No artifact binary file found in current directory (plasmactl_*)))
	@echo "(This can take some time)"
	@$(foreach ARTIFACT_BINARY,$(ARTIFACT_BINARIES), \
		curl -kL --keepalive-time 30 --retry 20 --retry-all-errors -s --user '${PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME}:${PLASMACTL_ARTIFACT_REPOSITORY_USER_PW}' --upload-file '${ARTIFACT_BINARY}' https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/repository/${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}/${TARGET_VERSION}/${ARTIFACT_BINARY}; \
	)
	@echo "-- Included plugins:"
	@grep ${BUILD_LOG_FILTER} $(BUILD_LOG_FILE) | ${BUILD_LOG_STRING_TR} | while IFS= read -r line; do \
		echo "$${line}"; \
		curl -kL --keepalive-time 30 --retry 20 --retry-all-errors -s --user '${PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME}:${PLASMACTL_ARTIFACT_REPOSITORY_USER_PW}' --upload-file "$${line}" https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/repository/${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}/${TARGET_VERSION}/"$(echo $${line} | sed 's| |%20|g')"; \
	done
	@echo "-- Done."

.PHONY: pin
## Pin new target version as stable_release
pin:
	@echo "- Action: pin"
	@echo "-- Pinning ${TARGET_VERSION} as stable_release..."
	$(shell echo "${TARGET_VERSION}" > stable_release)
	@curl -kL --keepalive-time 30 --retry 20 -s --user '${PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME}:${PLASMACTL_ARTIFACT_REPOSITORY_USER_PW}' --upload-file "${STABLE_RELEASE_FILE_NAME}" https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/repository/${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}/${STABLE_RELEASE_FILE_NAME} --fail || exit 1
	@echo "-- Done."
	@echo

.PHONY: validate
## Validate that stable_release has been updated on remote
validate: evaluate_remote_stable_release
	@echo "- Action: validate"
	@echo "-- Validating that stable_release has been updated on remote..."
	@echo "TARGET_VERSION: $(TARGET_VERSION)"
	@echo "REMOTE_STABLE_RELEASE: $(REMOTE_STABLE_RELEASE)"
	$(if $(value REMOTE_STABLE_RELEASE),,$(error ERROR: REMOTE_STABLE_RELEASE is empty or unset))
	@if [ "$(TARGET_VERSION)" != "$(REMOTE_STABLE_RELEASE)" ]; then echo "-- Error: Remote version does not seem to have been updated as expected."; exit 1; else echo "-- Versions match.";fi
	@echo "-- Done."
	@echo

.PHONY: getplasmactl
## Upload latest getplasmactl script to Nexus repository. It then can be used to easily download the right plasmactl binary according to your system
getplasmactl:
	@echo "- Action: getplasmactl"
	$(eval FILE_NAME = get-plasmactl.sh)
	@test -f ${FILE_NAME} || (echo "Error: ${FILE_NAME} file not found in current directory" && exit 1)
	@echo "-- Pushing get-plasmactl.sh to https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/#browse/browse:${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}..."
	$(if $(PLASMACTL_ARTIFACT_REPOSITORY_USER_PW),,$(error PLASMACTL_ARTIFACT_REPOSITORY_USER_PW is not set: You need to pass it as make command argument))
	@curl -kL --keepalive-time 30 --retry 20 --retry-all-errors -s --user '${PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME}:${PLASMACTL_ARTIFACT_REPOSITORY_USER_PW}' --upload-file '${FILE_NAME}' https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/repository/${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}/${FILE_NAME}
	@echo "-- Done."
	@echo

