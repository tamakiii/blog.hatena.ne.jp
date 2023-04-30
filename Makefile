.PHONY: help setup teardown pull draft entry

include function.mk

export BLOGSYNC_USERNAME ?= $(call env,BLOGSYNC_USERNAME)
export BLOGSYNC_PASSWORD ?= $(call env,BLOGSYNC_PASSWORD)
export BLOGSYNC_DOMAIN ?= $(call env,BLOGSYNC_DOMAIN)

TITLE :=

help:
	@cat $(firstword $(MAKEFILE_LIST))

setup:
	$(MAKE) -f env.mk $@

pull: \
	entry

draft:
	test -z "$(TITLE)" && { echo 'TITLE required'; exit 1; } || true
	blogsync post --draft --title="$(TITLE)" $(BLOGSYNC_DOMAIN)

entry:
	blogsync pull $(BLOGSYNC_DOMAIN)

teardown:
	$(MAKE) -f env.mk $@
