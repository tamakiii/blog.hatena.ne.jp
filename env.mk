.PHONY: help setup teardown

export IMAGE ?= $(shell basename $$(git rev-parse --show-toplevel))
export TAG ?= latest
export BLOGSYNC_USERNAME ?=
export BLOGSYNC_PASSWORD ?=
export BLOGSYNC_DOMAIN ?=

help:
	@cat $(firstword $(MAKEFILE_LIST))

setup: \
	.env

.env:
	touch $@
	@echo IMAGE=$(IMAGE) >> $@
	@echo TAG=$(TAG) >> $@
	@echo BLOGSYNC_USERNAME=$(BLOGSYNC_USERNAME) >> $@
	@echo BLOGSYNC_PASSWORD=$(BLOGSYNC_PASSWORD) >> $@
	@echo BLOGSYNC_DOMAIN=$(BLOGSYNC_DOMAIN) >> $@

teardown:
	 rm -rf .env
