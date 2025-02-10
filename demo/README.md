## Start Trustify

```shell
podman compose up
```

Open the UI at http://localhost:8080

username: admin
password: admin

## Open Jaeger

Open http://localhost:16686

## Open Prometheus

The backend exposes metrics at http://localhost:9010/metrics

Open the Prometheus UI at http://localhost:9091

Verify Prometheus is pulling data at http://localhost:9091/targets

We can query Prometheus with queries like:

```shell
trustify_http_requests_duration_seconds_bucket
trustify_http_requests_total
```

See available metrics using:
```shell
topk(100, {__name__!=""})
```