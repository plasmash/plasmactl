include helpers/*.mk

.PHONY: all build push

BINARY_REPO := github.com/launchrctl/launchr
BINARY_URL := https://${BINARY_REPO}
BINARY_NAME := launchr_${UNAME_S}_${UNAME_P}
BINARY_CHECKSUM_EXPECTED := $(shell curl -sL ${BINARY_URL}/releases/latest/download/checksums.txt | grep "${BINARY_NAME}" | awk '{print $$1}')


all: | provision build push

xx:
	@echo "${SYSTEM_OS}"
	@echo "${SYSTEM_PROCESSOR}"
	@echo "${UNAME_S}"
	@echo "${UNAME_P}"


## target desc
provision:
	echo provision
	curl -O -L ${BINARY_URL}/releases/latest/download/${BINARY_NAME}
	echo '${BINARY_CHECKSUM_EXPECTED} ${BINARY_NAME}' | sha256sum --check
	chmod +x ${BINARY_NAME}

## target desc
build:
	echo build
	GOOS=${SYSTEM_OS} GOARCH=${SYSTEM_PROCESSOR} ./${BINARY_NAME} build -p github.com/launchrctl/compose -n plasmactl # Does it provide .exe extension ?

## target desc
push:
	echo push
