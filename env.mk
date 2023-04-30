.PHONY: help setup teardown

export USERNAME ?= $(shell git config user.name)
export REPOSITORY ?= $(shell basename $$(git rev-parse --show-toplevel))
export IMAGE ?= $(USERNAME)/$(REPOSITORY)
export TAG ?= latest
export BLOGSYNC_USERNAME ?=
export BLOGSYNC_PASSWORD ?=

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

teardown:
	 rm -rf .env
