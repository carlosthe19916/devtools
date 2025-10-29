FROM quay.io/fedora/fedora:42

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

COPY entrypoint.sh /entrypoint.sh

RUN dnf -y update && \
    dnf install -y @development-tools && \
    dnf install -y @c-development && \
    dnf install -y curl wget && \
    # Neovim RPMs \
    dnf install -y neovim luarocks fzf ripgrep fd-find magick gs perl python-pip ruby-devel && \
    # Lazy git \
    dnf copr enable -y dejan/lazygit && \
    dnf install -y lazygit && \
    # Terminal \
    dnf copr enable -y scottames/ghostty && \
    dnf install -y ghostty && \
    # Tectonic \
    curl --proto '=https' --tlsv1.2 -fsSL https://drop-sh.fullyjustified.net |sh && \
    mv tectonic /usr/bin/

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo $USERNAME:10000:5000 > /etc/subuid && echo $USERNAME:10000:5000 > /etc/subgid && \
    # Allow user to execute 'sudo' without password \
    usermod -aG wheel $USERNAME && \
    echo "%wheel ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers > /dev/null

# set permissions
RUN chown $USERNAME:$USERNAME -R /home/$USERNAME

RUN usermod -aG wheel $USERNAME && \
    # Allow user to execute 'sudo' without password \
    echo "%wheel ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers > /dev/null

ENV _CONTAINERS_USERNS_CONFIGURED=""

ENTRYPOINT [ "/entrypoint.sh" ]
USER $USERNAME
CMD ["tail", "-f", "/dev/null"]
