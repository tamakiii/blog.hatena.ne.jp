env = $(shell test -f .env && export $$(cat .env | xargs) && echo $$$1)
