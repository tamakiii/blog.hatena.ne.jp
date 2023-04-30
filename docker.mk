.PHONY: help setup build bash teardown clean

include function.mk

export USERNAME ?= $(call env,USERNAME)
export REPOSITORY ?= $(call env,REPOSITORY)
export IMAGE ?= $(call env,IMAGE)
export TAG := $(call env,TAG)

help:
	@cat $(firstword $(MAKEFILE_LIST))

setup:
	$(MAKE) -f env.mk $@

build: Dockerfile
	docker build -t $(IMAGE):$(TAG) .

bash: build
	docker run --rm -it -v $(PWD):/opt/$(USER)/$(REPOSITORY) -w /opt/$(USER)/$(REPOSITORY) $(IMAGE):$(TAG) $@

teardown:
	$(MAKE) -f env.mk $@

clean:
	docker image rm $(IMAGE):$(TAG)
