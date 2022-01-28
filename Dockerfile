FROM debian:bullseye-20211220

# Install basic dev packages
RUN apt-get clean && apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    apt-utils \
    openssh-client \
    git \
    gnupg2 \
    dirmngr \
    iproute2 \
    procps \
    lsof \
    htop \
    net-tools \
    psmisc \
    curl \
    wget \
    rsync \
    ca-certificates \
    unzip \
    zip \
    nano \
    vim \
    neovim \
    less \
    jq \
    lsb-release \
    apt-transport-https \
    dialog \
    libc6 \
    libgcc1 \
    libkrb5-3 \
    libgssapi-krb5-2 \
    libicu[0-9][0-9] \
    liblttng-ust0 \
    libstdc++6 \
    zlib1g \
    locales \
    sudo \
    ncdu \
    man-db \
    strace \
    manpages \
    manpages-dev \
    init-system-helpers \
    make \
#java
    default-jre-headless \
# python runtime dependencies
    openssl \
    bzip2 \
    libreadline8 \
    sqlite3 \
    tk \
    xz-utils \
    libxml2 \
    llvm \
# some useful dev utils
    fd-find \
    bat \
    tree \
    zsh && \
    ln -s $(which fdfind) /usr/local/bin/fd && \
    ln -s $(which batcat) /usr/local/bin/bat

# ensure we use bash for all RUN commands
SHELL ["/bin/bash", "-lc"]

# install omyzsh goodness
RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
COPY ./resources/.zshrc /root/.zshrc

# install asdf to manage all the thingz!!!
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.1 && \
    echo ". $HOME/.asdf/asdf.sh" >> /root/.bashrc && \
    echo ". $HOME/.asdf/asdf.sh" >> /root/.zshrc
COPY ./resources/python_install_build_deps /usr/local/bin
COPY ./resources/python_remove_build_deps /usr/local/bin
COPY ./resources/.tool-versions /root/.asdf
RUN chmod +x /usr/local/bin/python_install_build_deps && \
    chmod +x /usr/local/bin/python_remove_build_deps
RUN asdf plugin add nodejs && \
    asdf plugin add python && \
    asdf plugin add golang

# install python build dependencies since asdf
# builds from the source
RUN python_install_build_deps && \
    cd /root/.asdf && \
    asdf install && \
    asdf global python 3.9.6 && \
    asdf global nodejs 14.18.2 && \
# remove build dependencies
# dev can add to install additional versions
# with python_install_build_deps
    python_remove_build_deps && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

# upgrade python and node package managers and install nx workspace manager
RUN pip install --upgrade pip && npm i -g npm@latest && \
    pip install pipenv==v2021.11.23 && npm i -g yarn@1.22 && \
    npm i -g nx && \
    rm -rf /root/.cache

# install docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian  $(lsb_release -cs) stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get -y --no-install-recommends install docker-ce=5:20.10.12~3-0~debian-bullseye docker-ce-cli=5:20.10.12~3-0~debian-bullseye containerd.io && \
    rm -rf /var/lib/apt/lists/*
    
# install aws cli v2
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip -o /tmp/awscliv2.zip && \
    cd /tmp && unzip awscliv2.zip && aws/install && \
    rm -rf /tmp/**

# install boto3
RUN pip install boto3

# some aws goodness utils
# install golang
RUN asdf install golang 1.17.5 && \
    asdf global golang 1.17.5 && \
# install aws-sso
    git clone --depth 1 --branch v1.6.0 https://github.com/synfinatic/aws-sso-cli.git /tmp/aws-sso && \
    cd /tmp/aws-sso && make && make install && \
# remove golang (can be added by dev if needed)
    asdf uninstall golang 1.17.5 && \
    asdf current && \
    rm -rf /tmp/** && \
    rm -rf /root/.cache
    
COPY resources/aws-assume /usr/local/bin/aws-assume

RUN cd /bin && ln -sf zsh sh && chsh -s /bin/zsh
ENV SHELL=zsh
WORKDIR /root
ENTRYPOINT [ "/bin/zsh", "-lc" ]