include helpers/*.mk

BINARY_REPO := github.com/launchrctl/launchr
BINARY_URL := https://${BINARY_REPO}
ifeq ($(UNAME_P),unknown)
BINARY_NAME := launchr_${UNAME_S}_x86_64
else
BINARY_NAME := launchr_${UNAME_S}_${UNAME_P}
endif
BINARY_CHECKSUM_EXPECTED := $(shell curl -sL ${BINARY_URL}/releases/latest/download/checksums.txt | grep "${BINARY_NAME}" | awk '{print $$1}')
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
all: | xx provision build push clean

.PHONY: provision
## target desc provision
provision:
	@echo "- Action: provision"
	@echo "-- Getting launchr binary file compatible with your machine..."
	curl -O -L ${BINARY_URL}/releases/latest/download/${BINARY_NAME}
	#echo '${BINARY_CHECKSUM_EXPECTED} ${BINARY_NAME}' | sha256sum --check
	chmod +x ${BINARY_NAME}
	@echo "-- Done."

.PHONY: build
## target desc build
build:
	@echo "- Action: build"
	@echo "-- Building plasmactl (launch + plugins) binaries compatible with all os/arch..."
	@echo ==========
	$(foreach SYSTEM_OS,$(ALL_SYSTEM_OS), \
		$(foreach SYSTEM_PROCESSOR,$(ALL_SYSTEM_PROCESSORS), \
			echo "Compiling artifact plasmactl_${SYSTEM_OS}_${SYSTEM_PROCESSOR}..." ; \
			GOOS=${SYSTEM_OS} GOARCH=${SYSTEM_PROCESSOR} ./${BINARY_NAME} build -p github.com/launchrctl/compose -n plasmactl -o plasmactl_${SYSTEM_OS}_${SYSTEM_PROCESSOR} ; \
		) \
	)
	@echo ==========
	@echo "-- Done."


.PHONY: push
## target desc push
push:
	@echo "- Action: push"
	@echo "-- Pushing platmactl binaries online..."
	$(if $(PLASMACTL_ARTIFACT_REPOSITORY_USER_PW),,$(error PLASMACTL_ARTIFACT_REPOSITORY_USER_PW is not set: You need to pass it as make command argument))
	$(eval ARTIFACT_BINARIES = $(shell ls plasmactl_*))
	$(if $(ARTIFACT_BINARIES),,$(error No artifact binary file found in current directory (plasmactl_*)))
	@$(foreach ARTIFACT_BINARY,$(ARTIFACT_BINARIES), \
		echo "Pushing ${ARTIFACT_BINARY} to https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/#browse/browse:${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}..." ; \
		curl -kL --keepalive-time 30 --retry 20 --retry-all-errors --user '${PLASMACTL_ARTIFACT_REPOSITORY_USER_NAME}:${PLASMACTL_ARTIFACT_REPOSITORY_USER_PW}' --upload-file '${ARTIFACT_BINARY}' https://${PLASMACTL_ARTIFACT_REPOSITORY_URL}/repository/${PLASMACTL_ARTIFACT_REPOSITORY_RAW_NAME}/latest/${ARTIFACT_BINARY} ; \
	)
	@echo "-- Done."


.PHONY: clean
## target desc clean
clean:
	@echo "- Action: clean"



