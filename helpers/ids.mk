
# Get user/group id to manage permissions between host and containers
LOCAL_UID := $(shell id -u)
LOCAL_GID := $(shell id -g)

# Evaluate recursively
CUID ?= $(LOCAL_UID)
CGID ?= $(LOCAL_GID)

