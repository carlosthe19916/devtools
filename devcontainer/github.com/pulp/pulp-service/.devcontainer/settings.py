import os

# Thin bootstrap. RH / ClowdApp knobs (incl. DB_ENCRYPTION_KEY, WORKER_TYPE) live in pulp-dev.env.
SECRET_KEY = "dev-secret-key-not-for-production"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "pulp",
        "USER": "pulp",
        "PASSWORD": os.environ.get("DB_PASSWORD", "pulp"),
        "HOST": os.environ.get("DB_HOST", "localhost"),
        "PORT": "5432",
    }
}

REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")

MEDIA_ROOT = "/var/lib/pulp/media/"
DEFAULT_FILE_STORAGE = "pulpcore.app.models.storage.FileSystem"
WORKING_DIRECTORY = "/var/lib/pulp/tmp/"

CSRF_TRUSTED_ORIGINS = ["http://localhost:24817", "http://localhost:80", "http://localhost"]
