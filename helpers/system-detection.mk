# List of available OS:
# - windows
# - darwin
# - linux
# List of available processors
# - amd64
# - ia32 (Intel x86)
# - arm
ifeq ($(OS),Windows_NT)
    SYSTEM_OS = windows
    ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
        SYSTEM_PROCESSOR = amd64
    else
        ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
        	SYSTEM_PROCESSOR = amd64
        endif
        ifeq ($(PROCESSOR_ARCHITECTURE),x86)
        	SYSTEM_PROCESSOR = ia32
        endif
    endif
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
	    SYSTEM_OS = linux
    endif
    ifeq ($(UNAME_S),Darwin)
        SYSTEM_OS = darwin
        CUID=1000
        CGID=1000
    endif
    # Use uname -m as primary (more reliable), fallback to uname -p
    UNAME_M := $(shell uname -m)
    ifeq ($(UNAME_M),x86_64)
        UNAME_P := x86_64
        SYSTEM_PROCESSOR = amd64
    else ifeq ($(UNAME_M),aarch64)
        UNAME_P := arm64
        SYSTEM_PROCESSOR = arm64
    else ifeq ($(UNAME_M),arm64)
        UNAME_P := arm64
        SYSTEM_PROCESSOR = arm64
    else
        UNAME_P := $(shell uname -p)
        ifeq ($(UNAME_P),x86_64)
            SYSTEM_PROCESSOR = amd64
        endif
        ifneq ($(filter %86,$(UNAME_P)),)
            SYSTEM_PROCESSOR = ia32
        endif
        ifneq ($(filter arm%,$(UNAME_P)),)
            SYSTEM_PROCESSOR = arm
        endif
    endif
endif
