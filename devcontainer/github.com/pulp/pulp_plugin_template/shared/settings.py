import os

CONTENT_ORIGIN = "http://localhost:24816"
CONTENT_PATH_PREFIX = "/api/pulp-content/"
PYPI_PATH_PREFIX = "/api/pypi/"
PYPI_API_HOSTNAME = "http://localhost:24817"
DOMAIN_ENABLED = False
API_ROOT = "/pulp/"
SECRET_KEY = "dev-secret-key-not-for-production"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "pulp",
        "USER": "pulp",
        "PASSWORD": "pulp",
        "HOST": os.environ.get("DB_HOST", "localhost"),
        "PORT": "5432",
    }
}

REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
CACHE_ENABLED = True
WORKER_TYPE = "redis"

MEDIA_ROOT = "/var/lib/pulp/media/"
DEFAULT_FILE_STORAGE = "pulpcore.app.models.storage.FileSystem"
WORKING_DIRECTORY = "/var/lib/pulp/tmp/"

ALLOWED_CONTENT_CHECKSUMS = ["sha224", "sha256", "sha384", "sha512"]

TOKEN_AUTH_DISABLED = True
CSRF_TRUSTED_ORIGINS = ["http://localhost:24817", "http://localhost:80", "http://localhost"]

DISTRIBUTED_PUBLICATION_RETENTION_PERIOD = 5

ALLOWED_IMPORT_PATHS = ["/tmp"]
ALLOWED_EXPORT_PATHS = ["/tmp"]
