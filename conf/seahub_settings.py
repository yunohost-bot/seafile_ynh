SECRET_KEY = "__SEAHUB_SECRET_KEY__"

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'seahubdb',
        'USER': '__DB_USER__',
        'PASSWORD': '__DB_PWD__',
        'HOST': '127.0.0.1',
        'PORT': '3306',
        'OPTIONS': {
            'init_command': 'SET storage_engine=INNODB',
        }
    }
}

SERVICE_URL =  "https://__DOMAIN____PATH__"
FILE_SERVER_ROOT = "https://__DOMAIN__/seafhttp"
SITE_ROOT = "__PATH2__"
SERVE_STATIC = False
MEDIA_URL = "__PATH2__media/"
COMPRESS_URL = MEDIA_URL
STATIC_URL = MEDIA_URL + 'assets/'
EMAIL_USE_TLS = False
EMAIL_HOST = "localhost"
EMAIL_HOST_USER = "__APP__"
EMAIL_HOST_PASSWORD = "__MAIL_PWD__"
EMAIL_PORT = "25"
DEFAULT_FROM_EMAIL = "__APP__@__DOMAIN__"
SERVER_EMAIL = "__APP__@__DOMAIN__"
LOGIN_URL = '__PATH2__accounts/login/'
ENABLE_WIKI = True
ALLOWED_HOSTS = ['__DOMAIN__']
ENABLE_REMOTE_USER_AUTHENTICATION = True
REMOTE_USER_HEADER = 'HTTP_EMAIL'
REMOTE_USER_CREATE_UNKNOWN_USER = False
REMOTE_USER_PROTECTED_PATH = ['__PATH__', '__PATH2__accounts/login']
TIME_ZONE = "__TIME_ZONE__"
CACHES = {
    'default': {
        'BACKEND': 'django_pylibmc.memcached.PyLibMCCache',
        'LOCATION': '127.0.0.1:11211',
    },
}
