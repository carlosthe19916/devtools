FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Build context: devcontainer/github.com/pulp (parent).
# Compose: dockerfile: pulp-service/.devcontainer/Dockerfile

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
    touch /etc/nginx/pulp/.keep.conf

# Test attestation keypair for functional tests that sign locally.
RUN sudo mkdir -p /etc/pki/attestation && \
    sudo openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 \
        -out /etc/pki/attestation/test-key-private.pem && \
    sudo openssl pkey -in /etc/pki/attestation/test-key-private.pem -pubout \
        -out /etc/pki/attestation/test-key.pem && \
    sudo chmod 644 /etc/pki/attestation/test-key-private.pem \
        /etc/pki/attestation/test-key.pem

COPY pulp-dev-common/settings.py /etc/pulp/settings.py
COPY pulp-service/.devcontainer/config/nginx.conf /etc/nginx/nginx.conf
COPY pulp-dev-common/config/nginx-proxy-params.conf /etc/nginx/pulp-proxy-params.conf

ENV DJANGO_SETTINGS_MODULE=pulpcore.app.settings
ENV PULP_SETTINGS=/etc/pulp/settings.py
ENV PULP_DEV_SCRIPTS=/opt/pulp-dev/scripts
ENV PULP_DEV_CONFIG=/opt/pulp-dev/config
ENV PULP_DEV_SKILLS=/opt/pulp-dev/skills
ENV PULP_POPULATE_ROOT=/opt/pulp-dev/populate
