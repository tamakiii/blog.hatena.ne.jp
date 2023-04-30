FROM ubuntu:23.04

RUN apt update && \
		apt install -y \
			build-essential \
			curl \
			git \
			&& \
		apt clean all

RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
		(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /root/.profile

ENV PATH /home/linuxbrew/.linuxbrew/bin:$PATH

RUN brew install Songmu/tap/blogsync
