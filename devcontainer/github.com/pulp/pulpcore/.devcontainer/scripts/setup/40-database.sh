#!/usr/bin/env bash
set -euo pipefail

python3 -c "import redis; redis.from_url('$REDIS_URL').flushall(); print('Redis flushed')" 2>/dev/null || true
pulpcore-manager migrate --noinput
pulpcore-manager reset-admin-password --password password
