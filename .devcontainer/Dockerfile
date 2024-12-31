FROM quay.io/fedora/fedora:41

RUN dnf -y update && \
    yum install -y git && \
    git config --global --add safe.directory /workspace && \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.*
COPY entrypoint.sh /entrypoint.sh
RUN useradd -u 1000 vscode && echo vscode:10000:5000 > /etc/subuid && echo vscode:10000:5000 > /etc/subgid

# set permissions
RUN chown vscode:vscode -R /home/vscode

RUN usermod -aG wheel vscode && \
    # Allow user to execute 'sudo' without password
    echo "%wheel ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers > /dev/null && \
    # https://github.com/containers/podman/issues/2788#issuecomment-479923274
    chmod 4755 /usr/bin/newgidmap && chmod 4755 /usr/bin/newuidmap

ENV _CONTAINERS_USERNS_CONFIGURED=""

ENTRYPOINT [ "/entrypoint.sh" ]
USER vscode
CMD ["tail", "-f", "/dev/null"]
