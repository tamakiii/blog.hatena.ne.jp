FROM ubuntu:23.04

RUN apt update && \
    apt install -y \
        build-essential \
        curl \
        git \
        && \
    apt clean all

# Create a new non-root user and switch to that user
RUN useradd -m -s /bin/bash user
USER user
WORKDIR /home/user

# Install Homebrew using the "untar anywhere" method
RUN mkdir homebrew && \
    curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew

# Add Homebrew to the user's PATH
RUN echo 'eval "$(/home/user/homebrew/bin/brew shellenv)"' >> ~/.profile && \
    echo 'export PATH="/home/user/homebrew/bin:$PATH"' >> ~/.profile

# Update the PATH in the current shell session
ENV PATH /home/user/homebrew/bin:$PATH

# Install blogsync
RUN brew update --quiet && \
    brew install Songmu/tap/blogsync

RUN chmod u+x /home/user/homebrew/Cellar/blogsync/0.13.5/bin/blogsync
