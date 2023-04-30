FROM ubuntu:23.04

RUN apt update && \
    apt install -y \
        build-essential \
        curl \
        git \
        && \
    apt clean all

RUN apt update && \
		apt install -y \
			golang-go \
			&& \
		apt clean all

RUN go install github.com/x-motemen/blogsync@latest

ENV PATH /root/go/bin:$PATH
