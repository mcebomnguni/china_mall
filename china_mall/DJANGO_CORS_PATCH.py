# ============================================================
# ADD THESE LINES to your Django settings.py
# File: chinamall_django/chinamall_export/config/settings.py
# ============================================================

# Replace the existing CORS lines with these:
CORS_ALLOW_ALL_ORIGINS = True   # Allow all origins in development

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

# ============================================================
# Also restart Django after saving:
# python manage.py runserver 0.0.0.0:8000
# ============================================================
