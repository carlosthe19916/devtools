FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN sudo apt update && \
    sudo apt install -y build-essential libpq-dev jq nginx postgresql-client redis-tools redis-server \
        libglib2.0-0 rpm
# libglib2.0-0: createrepo_c (pulp-rpm) needs libgobject-2.0.so.0 / libglib-2.0.so.0
# rpm: provides /usr/lib/rpm/rpmrc used when pulp-rpm/createrepo_c touch RPM metadata

RUN mkdir -p /etc/pulp/certs && \
    openssl rand -base64 32 > /etc/pulp/certs/database_fields.symmetric.key

RUN mkdir -p /var/lib/pulp/assets\
             /var/lib/pulp/media \
             /var/lib/pulp/tmp \
             /etc/nginx/pulp \
             /etc/pki/sigstore && \
    # Keep include /etc/nginx/pulp/*.conf valid when no plugin snippets exist yet.
    touch /etc/nginx/pulp/.keep.conf

# Test attestation keypair for functional tests that sign locally.
# Production / pulp-docs verify with vendored Sigstore PEM (installed at postCreate
# from /workspace/images/assets/keys/). openssl avoids a Dockerfile parse hazard:
# a line starting with Python "from ..." is treated as FROM.
RUN sudo mkdir -p /etc/pki/attestation && \
    sudo openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 \
        -out /etc/pki/attestation/test-key-private.pem && \
    sudo openssl pkey -in /etc/pki/attestation/test-key-private.pem -pubout \
        -out /etc/pki/attestation/test-key.pem && \
    # readable by vscode so functional attestation tests can sign locally
    sudo chmod 644 /etc/pki/attestation/test-key-private.pem \
        /etc/pki/attestation/test-key.pem

# Bake RH nginx; proxy-params remounted from pulp-dev-common at postStart.
COPY settings.py /etc/pulp/settings.py
COPY config/nginx.conf /etc/nginx/nginx.conf

ENV DJANGO_SETTINGS_MODULE=pulpcore.app.settings
ENV PULP_SETTINGS=/etc/pulp/settings.py
ENV DEVCONTAINER_DEV_SCRIPTS=/opt/pulp-dev/scripts
ENV DEVCONTAINER_DEV_CONFIG=/opt/pulp-dev/config
ENV DEVCONTAINER_DEV_SKILLS=/opt/pulp-dev/skills
ENV DEVCONTAINER_POPULATE_ROOT=/opt/pulp-dev/populate
