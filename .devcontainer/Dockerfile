# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

ARG DockerUSER=deww
ARG DockerUID=503
ARG DockerGID=20

ENV DEBIAN_FRONTEND=noninteractive
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"
ENV DockerUSER=${DockerUSER}
ENV DockerUID=${DockerUID}
ENV DockerGID=${DockerGID}

# Update and install required packages
RUN apt-get update && apt-get install -y \
    curl \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    gnupg \
    git \
    sudo \
    bash-completion \
    build-essential \
    vim \
    jq

USER root

# Create non-root user
RUN if getent passwd $DockerUID > /dev/null; then userdel -rf $(getent passwd $DockerUID | cut -d ':' -f 1); fi \
    && groupadd --force --gid $DockerGID $DockerUSER \
    && useradd --no-log-init --uid $DockerUID --gid $DockerGID -m $DockerUSER \
    && mkdir -p /etc/sudoers.d/ \
    && echo $DockerUSER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$DockerUSER \
    && chmod 0440 /etc/sudoers.d/$DockerUSER

USER $DockerUSER

# Install Homebrew
RUN echo "Installing Homebrew..." && \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"' >> \
    /home/${DockerUSER}/.bashrc


RUN brew install starship lazygit fzf fd ripgrep tmux btop eza neovim zsh gh azure-cli kubectx kubectl helm terraform kubelogin python go rust




RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone https://github.com/zsh-users/zsh-autosuggestions /home/${DockerUSER}/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone https://github.com/lukechilds/zsh-nvm /home/${DockerUSER}/.oh-my-zsh/custom/plugins/zsh-nvm && \
    echo 'eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"' >> /home/${DockerUSER}/.zshrc


# Install NVM, Node.js LTS, and update .zshrc
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install --lts

CMD [ "zsh" ]