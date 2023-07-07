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
ALL_SYSTEM_OS := darwin linux windows
ALL_SYSTEM_PROCESSORS := amd64 arm64
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
all: | provision build push clean

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
	$(foreach SYSTEM_OS,$(ALL_SYSTEM_OS), \
		$(foreach SYSTEM_PROCESSOR,$(ALL_SYSTEM_PROCESSORS), \
			echo "Compiling artifact plasmactl_${SYSTEM_OS}_${SYSTEM_PROCESSOR}..." ; \
			GOOS=${SYSTEM_OS} GOARCH=${SYSTEM_PROCESSOR} ./${BINARY_NAME} build -p github.com/launchrctl/compose -n plasmactl -o plasmactl_${SYSTEM_OS}_${SYSTEM_PROCESSOR} ; \
		) \
	)
	@echo "-- Artifacts generated:"
	@$(foreach file, $(wildcard plasmactl_*), printf "%s\n" "$(file)";)
	@echo "-- Done."
	@echo

.PHONY: push
## Upload artifacts (plasmactl binaries) to an online raw repository
push:
	@echo "- Action: push"
	@echo "-- Pushing platmactl binaries to https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/#browse/browse:${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}..."
	$(if $(PLASMACTL_ARTIFACT_REPOSITORY_USER_PW),,$(error PLASMACTL_ARTIFACT_REPOSITORY_USER_PW is not set: You need to pass it as make command argument))
	echo "(This can take some time)"
	$(foreach ARTIFACT_BINARY, $(wildcard plasmactl_*), \
		curl -kL --keepalive-time 30 --retry 20 --retry-all-errors --user '${PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME}:${PLASMACTL_ARTIFACT_REPOSITORY_USER_PW}' --upload-file '${ARTIFACT_BINARY}' https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/repository/${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}/latest/${ARTIFACT_BINARY} >/dev/null 2>&1 ; \
		curl -kL --keepalive-time 30 --retry 20 --retry-all-errors --user '${PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME}:${PLASMACTL_ARTIFACT_REPOSITORY_USER_PW}' --upload-file '${ARTIFACT_BINARY}' https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/repository/${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}/${BINARY_RELEASE_VERSION}/${ARTIFACT_BINARY} >/dev/null 2>&1 ; \
	)
	@echo "-- Done."
	@echo

x:
	@$(foreach file, $(wildcard plasmactl_*), printf "%s\n" "$(file)";)


