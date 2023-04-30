.PHONY: help setup build bash teardown clean

include function.mk

export IMAGE ?= $(call env,IMAGE)
export TAG := $(call env,TAG)
PLATFORM := $(uname )

help:
	@cat $(firstword $(MAKEFILE_LIST))

setup:
	$(MAKE) -f env.mk $@

build: Dockerfile
	docker build -t $(IMAGE):$(TAG) .

bash: build
	docker run --rm -T $(IMAGE):$(TAG) $@

teardown:
	$(MAKE) -f env.mk $@

clean:
	docker image rm $(IMAGE):$(TAG)
