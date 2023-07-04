include helpers/*.mk

.PHONY: all build push

$(eval BINARY_NAME := launchr_${UNAME_S}_${UNAME_P})

all: | provision build push

xx:
	@echo "${SYSTEM_OS}"
	@echo "${SYSTEM_PROCESSOR}"
	@echo "${UNAME_S}"
	@echo "${UNAME_P}"
	@echo "launchr_${UNAME_S}_${UNAME_P}"
	@echo "${BINARY_NAME}"


## target desc
provision:
	echo provision
	curl -O -L https://github.com/launchrctl/launchr/releases/latest/download/${BINARY_NAME}
	chmod +x ${BINARY_NAME}
	./${BINARY_NAME}


## target desc
build:
	echo build

## target desc
push:
	echo push
