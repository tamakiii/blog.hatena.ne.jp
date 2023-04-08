.PHONY: help setup teardown
.PHONY: pull

env = $(shell test -f .env && export $$(cat .env | xargs) && echo $$$1)

export BLOGSYNC_USERNAME ?= $(call env,BLOGSYNC_USERNAME)
export BLOGSYNC_PASSWORD ?= $(call env,BLOGSYNC_UPASSWORD)
export BLOGSYNC_DOMAIN ?= $(call env,BLOGSYNC_DOMAIN)

help:
	@cat $(firstword $(MAKEFILE_LIST))

setup: \
	.env

pull: \
	entry

entry:
	blogsync pull $(BLOGSYNC_DOMAIN)

teardown:
	rm -rf .env

.env:
	touch $@
	@echo BLOGSYNC_USERNAME=$(BLOGSYNC_USERNAME) >> $@
	@echo BLOGSYNC_PASSWORD=$(BLOGSYNC_PASSWORD) >> $@
	@echo BLOGSYNC_DOMAIN=$(BLOGSYNC_DOMAIN) >> $@
