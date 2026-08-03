import json, time, os, traceback, importlib.metadata as m

ts = int(time.time() * 1000)


def emit(hid, loc, msg, data):
    rec = {
        "sessionId": "cc5989",
        "runId": os.environ.get("DEBUG_RUN_ID", "pre-fix"),
        "hypothesisId": hid,
        "location": loc,
        "message": msg,
        "data": data,
        "timestamp": ts,
    }
    print(json.dumps(rec), flush=True)


installed = m.version("pulpcore")
req_line = None
for line in open("/workspace/pulp_service/requirements.txt"):
    if "pulpcore" in line:
        req_line = line.strip()
        break
emit(
    "A",
    "probe:version",
    "pulpcore installed vs requirements",
    {
        "installed": installed,
        "requirements_line": req_line,
        "mismatch": req_line is not None and installed not in req_line,
    },
)

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "pulpcore.app.settings")
import django

django.setup()
from django.db import connection, transaction
from pulpcore.app.models import Task

with connection.cursor() as c:
    c.execute(
        "SELECT is_nullable, data_type FROM information_schema.columns "
        "WHERE table_name='core_task' AND column_name='pulp_api_version'"
    )
    col = c.fetchall()
model_has = "pulp_api_version" in [f.name for f in Task._meta.get_fields()]
emit(
    "B",
    "probe:schema",
    "DB pulp_api_version vs Task model",
    {
        "db_column": col,
        "db_not_null": bool(col and col[0][0] == "NO"),
        "model_has_field": model_has,
        "skew": bool(col) and not model_has,
    },
)

err = None
try:
    with transaction.atomic():
        Task.objects.create(
            state="waiting", name="debug.probe", enc_args="[]", enc_kwargs="{}"
        )
        raise RuntimeError("unexpected success")
except Exception as e:
    err = f"{type(e).__name__}: {e}"
emit(
    "C",
    "probe:task_create",
    "Task.objects.create probe",
    {
        "error": err,
        "is_integrity_pulp_api_version": bool(err and "pulp_api_version" in err),
    },
)

from django.test import Client
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile

u = get_user_model().objects.get(username="admin")
c = Client()
c.force_login(u)
f = SimpleUploadedFile(
    "shelf-reader-0.1.tar.gz", b"x", content_type="application/octet-stream"
)
try:
    r = c.post(
        "/api/pulp/default/api/v3/content/python/packages/",
        data={"relative_path": "shelf-reader-0.1.tar.gz", "file": f},
        format="multipart",
    )
    emit(
        "D",
        "probe:content_create",
        "multipart content create status",
        {"status": r.status_code, "body": r.content[:300].decode("utf-8", "replace")},
    )
except Exception as e:
    emit(
        "D",
        "probe:content_create",
        "multipart content create exception",
        {"error": f"{type(e).__name__}: {e}", "tb": traceback.format_exc()[-800:]},
    )
