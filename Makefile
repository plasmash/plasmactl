include helpers/*.mk
BINARY_REPO := github.com/launchrctl/launchr
BINARY_URL := https://${BINARY_REPO}
ifeq ($(UNAME_P),unknown)
BINARY_NAME := launchr_${UNAME_S}_x86_64
else
BINARY_NAME := launchr_${UNAME_S}_${UNAME_P}
endif
BINARY_CHECKSUM_EXPECTED := $(shell curl -sL ${BINARY_URL}/releases/latest/download/checksums.txt | grep "${BINARY_NAME}" | awk '{print $$1}')
BINARY_RELEASE_VERSION := $(shell curl -s https://api.github.com/repos/launchrctl/launchr/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
TARGET_OSES := darwin linux windows
TARGET_ARCHES := amd64 arm64 386
PLASMACTL_ARTIFACT_REPOSITORY_URL := repositories.skilld.cloud
PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME := pla-plasmactl-raw
PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME := pla-plasmactl
PLASMACTL_BINARY_NAME := plasmactl_${UNAME_S}_${UNAME_P}

xx:
	@echo "${SYSTEM_OS}"
	@echo "${SYSTEM_PROCESSOR}"
	@echo "${UNAME_S}"
	@echo "${UNAME_P}"

.PHONY: all
## Everything below, sequentially
binaries: | provision build push clean

.PHONY: provision
## Download launchr binary corresponding to current OS & Arch
provision:
	@echo
	@echo "- Action: provision"
	@echo "-- Getting latest launchr binary file (release: ${BINARY_RELEASE_VERSION}) compatible with your OS & Arch..."
	curl -O -L ${BINARY_URL}/releases/latest/download/${BINARY_NAME}
	@echo "-- Comparing checksums..."
	echo '${BINARY_CHECKSUM_EXPECTED} ${BINARY_NAME}' | sha256sum --check
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
			GOOS=${TARGET_OS} GOARCH=${TARGET_ARCH} ./${BINARY_NAME} build -p github.com/launchrctl/compose@latest -p github.com/launchrctl/bump-updated@latest -n plasmactl -o plasmactl_${TARGET_OS}_${TARGET_ARCH}${EXTENSION} ; \
		) \
	)
	@echo "-- Artifacts generated:"
	ls -lah | grep plasmactl_
	@echo "-- Done."
	@echo

.PHONY: push
## Upload artifacts (plasmactl binaries) to an online raw repository
push:
	@echo "- Action: push"
	@echo "-- Pushing platmactl binaries to https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/#browse/browse:${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}..."
	$(if $(PLASMACTL_ARTIFACT_REPOSITORY_USER_PW),,$(error PLASMACTL_ARTIFACT_REPOSITORY_USER_PW is not set: You need to pass it as make command argument))
	$(eval ARTIFACT_BINARIES = $(shell ls plasmactl_*))
	$(if $(ARTIFACT_BINARIES),,$(error No artifact binary file found in current directory (plasmactl_*)))
	@echo "(This can take some time)"
	@$(foreach ARTIFACT_BINARY,$(ARTIFACT_BINARIES), \
		curl -kL --keepalive-time 30 --retry 20 --retry-all-errors --user '${PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME}:${PLASMACTL_ARTIFACT_REPOSITORY_USER_PW}' --upload-file '${ARTIFACT_BINARY}' https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/repository/${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}/latest/${ARTIFACT_BINARY} >/dev/null 2>&1 ; \
		curl -kL --keepalive-time 30 --retry 20 --retry-all-errors --user '${PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME}:${PLASMACTL_ARTIFACT_REPOSITORY_USER_PW}' --upload-file '${ARTIFACT_BINARY}' https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/repository/${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}/${BINARY_RELEASE_VERSION}/${ARTIFACT_BINARY} >/dev/null 2>&1 ; \
	)
	@echo "-- Done."
	@echo

.PHONY: getplasmactl
## Upload artifacts (plasmactl binaries) to an online raw repository
getplasmactl:
	@echo "- Action: push"
	$(eval FILE_NAME = get-plasmactl.sh)
	@test -f ${FILE_NAME} || (echo "Error: ${FILE_NAME} file not found in current directory" && exit 1)
	@echo "-- Pushing get-plasmactl.sh to https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/#browse/browse:${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}..."
	$(if $(PLASMACTL_ARTIFACT_REPOSITORY_USER_PW),,$(error PLASMACTL_ARTIFACT_REPOSITORY_USER_PW is not set: You need to pass it as make command argument))
	@curl -kL --keepalive-time 30 --retry 20 --retry-all-errors --user '${PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME}:${PLASMACTL_ARTIFACT_REPOSITORY_USER_PW}' --upload-file '${FILE_NAME}' https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/repository/${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}/${FILE_NAME} >/dev/null 2>&1
	@echo "-- Done."
	@echo

