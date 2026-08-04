FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN sudo apt update && \
    sudo apt install -y build-essential libpq-dev jq nginx postgresql-client redis-tools redis-server

RUN mkdir -p /etc/pulp/certs && \
    openssl rand -base64 32 > /etc/pulp/certs/database_fields.symmetric.key

RUN mkdir -p /var/lib/pulp/assets\
             /var/lib/pulp/media \
             /var/lib/pulp/tmp \
             /etc/nginx/pulp && \
    touch /etc/nginx/pulp/.keep.conf

# settings.py is local; nginx.conf comes from pulp-dev-common via PULP_NGINX_REMOUNT at postStart.
COPY settings.py /etc/pulp/settings.py

ENV DJANGO_SETTINGS_MODULE=pulpcore.app.settings
ENV PULP_SETTINGS=/etc/pulp/settings.py
ENV PULP_DEV_SCRIPTS=/opt/pulp-dev/scripts
ENV PULP_DEV_CONFIG=/opt/pulp-dev/config
ENV PULP_DEV_SKILLS=/opt/pulp-dev/skills
ENV PULP_PATCH_DIR=/opt/pulp-dev/patches
ENV PULP_POPULATE_ROOT=/opt/pulp-dev/populate
