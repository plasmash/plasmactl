include helpers/*.mk

.PHONY: all build push

BINARY_REPO := https://github.com/launchrctl/launchr
BINARY_NAME := launchr_${UNAME_S}_${UNAME_P}
BINARY_CHECKSUM_EXPECTED := $(shell curl -sL ${BINARY_REPO}/releases/latest/download/checksums.txt | grep "${BINARY_NAME}" | awk '{print $$1}')


all: | provision build push

xx:
	@echo "${BINARY_NAME}"
	@echo "${BINARY_CHECKSUM_EXPECTED}"
	echo '${BINARY_CHECKSUM_EXPECTED} ${BINARY_NAME}' | sha256sum --check


## target desc
provision:
	echo provision
	curl -O -L ${BINARY_REPO}/releases/latest/download/${BINARY_NAME}
	echo '${BINARY_CHECKSUM_EXPECTED} ${BINARY_NAME}' | sha256sum --check
	chmod +x ${BINARY_NAME}
	./${BINARY_NAME}


## target desc
build:
	echo build

## target desc
push:
	echo push
