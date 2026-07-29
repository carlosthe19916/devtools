# Pulp process helpers — API :24817, content :24816, worker.

pulp-api() {
  pulpcore-api --bind 127.0.0.1:24817 --timeout 90 --workers 2 --access-logfile -
}

pulp-content() {
  pulpcore-content --bind 127.0.0.1:24816 --timeout 90 --workers 2 --access-logfile -
}

pulp-worker() { pulpcore-worker; }

pulp-services() {
  concurrently --names "api,content,worker" --prefix-colors "green,blue,magenta" \
    "pulpcore-api --bind 127.0.0.1:24817 --timeout 90 --workers 2 --access-logfile -" \
    "pulpcore-content --bind 127.0.0.1:24816 --timeout 90 --workers 2 --access-logfile -" \
    "pulpcore-worker"
}
