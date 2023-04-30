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

# Install Homebrew as the non-root user
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to the user's PATH
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile && \
    echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> ~/.profile

# Update the PATH in the current shell session
ENV PATH /home/linuxbrew/.linuxbrew/bin:$PATH

# Install blogsync
RUN brew install Songmu/tap/blogsync