FROM ubuntu:23.04

RUN apt update && \
    apt install -y \
        build-essential \
        curl \
        git \
        golang-go \
        && \
    apt clean all

# Create a new non-root user and switch to that user
RUN useradd -m -s /bin/bash user
USER user
WORKDIR /home/user

# Install blogsync using go install
RUN go install github.com/x-motemen/blogsync@latest

# Update the PATH in the current shell session to include the Go bin directory
ENV PATH /home/user/go/bin:$PATH
