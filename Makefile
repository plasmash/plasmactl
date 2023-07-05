include helpers/*.mk

BINARY_REPO := github.com/launchrctl/launchr
BINARY_URL := https://${BINARY_REPO}
BINARY_NAME := launchr_${UNAME_S}_${UNAME_P}
BINARY_CHECKSUM_EXPECTED := $(shell curl -sL ${BINARY_URL}/releases/latest/download/checksums.txt | grep "${BINARY_NAME}" | awk '{print $$1}')
ALL_SYSTEM_OS := linux windows darwin
ALL_SYSTEM_PROCESSORS := amd64 arm64

xx:
	@echo "${SYSTEM_OS}"
	@echo "${SYSTEM_PROCESSOR}"
	@echo "${UNAME_S}"
	@echo "${UNAME_P}"


.PHONY: all
all: | provision build push clean

.PHONY: provision
## target desc provision
provision:
	echo provision
	curl -O -L ${BINARY_URL}/releases/latest/download/${BINARY_NAME}
	echo '${BINARY_CHECKSUM_EXPECTED} ${BINARY_NAME}' | sha256sum --check
	chmod +x ${BINARY_NAME}

.PHONY: build
## target desc build
build:
	echo build
	$(foreach SYSTEM_OS,$(ALL_SYSTEM_OS), \
		$(foreach SYSTEM_PROCESSOR,$(ALL_SYSTEM_PROCESSORS), \
			echo "${SYSTEM_OS}_${SYSTEM_PROCESSOR}" ; \
		) \
	)
	#GOOS=${SYSTEM_OS} GOARCH=${SYSTEM_PROCESSOR} ./${BINARY_NAME} build -p github.com/launchrctl/compose -n plasmactl # Does it provide .exe extension ? ; \


.PHONY: push
## target desc push
push:
	echo push
	$(eval ARTIFACT_BINARIES = $(shell ls plasmactl_*))
	$(foreach ARTIFACT,$(ARTIFACT_BINARIES), \
		echo ${ARTIFACT} ; \
	)


.PHONY: clean
## target desc clean
clean:
	echo clean



