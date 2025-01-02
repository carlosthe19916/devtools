podman system service --time=0 unix:///tmp/custom-podman.sock

export DOCKER_HOST=unix:///tmp/custom-podman.sock
export TESTCONTAINERS_RYUK_DISABLED=true

export DOCKER_HOST=unix:///var/run/docker-host.sock
export TESTCONTAINERS_RYUK_DISABLED=true

./mvnw test -Dtest=DefaultSpecTest
