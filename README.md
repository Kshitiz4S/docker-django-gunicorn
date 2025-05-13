# django docker deployment for production

```bash
FROM python:3.10-alpine

WORKDIR /app

# To stop Python from writing .pyc files at all inside the container.
ENV PYTHONDONTWRITEBYTECODE=1

# It tells Python not to buffer its output — meaning it will print everything immediately to stdout/stderr, rather than storing it temporarily (buffering) before printing.
ENV PYTHONUNBUFFERED=1

# Make sure gunicorn is present in requirements.txt file
COPY requirements.txt .

RUN pip install --upgrade pip

RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

# Gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "project.wsgi:application"]
```

```bash
# Install PostgreSQL and PostgreSQL-Client if not installed
# sudo apt install postgresql postgresql-client

# Create a database for project in server
sudo -i -u postgres
psql
CREATE DATABASE avm;
# since user postgress already exists just change the password for it inside avm database
ALTER USER postgres WITH PASSWORD 'newpassword';
GRANT ALL PRIVILEGES ON DATABASE avm TO postgres;
```

```bash
services:
  db:
    image: postgres:13
    container_name: newsblog_db
    restart: always
    env_file:
      - .env
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  app:
    build: .
    container_name: newsblog
    volumes:
      - ./newsblog:/app/newsblog
      - static_volume:/app/static  # collectstatic
    depends_on:
      - db
    env_file:
      - .env
    command: >
      sh -c "
        python3 manage.py collectstatic --noinput &&
        python3 manage.py makemigrations &&
        python3 manage.py migrate &&
        gunicorn project.wsgi:application --bind 0.0.0.0:8000
      "

  nginx:
    image: nginx:alpine
    container_name: newsblog_nginx
    depends_on:
      - app
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
      - static_volume:/static
    ports:
      - "80:80"

volumes:
  postgres_data:
  static_volume:

```

```bash
ALLOWED_HOSTS = localhost,127.0.0.1,192.168.19.14,app
CSRF_TRUSTED_ORIGINS = "http://localhost:8000,http://127.0.0.1:8000,http://192.168.19.14"
# CORS_ALLOWED_ORIGINS = http://localhost:3000,http://127.0.0.1:3000

STATIC_ROOT=/home/vagrant/project-folder/static

DB_ENGINE=django.db.backends.postgresql
DB_NAME=avm
DB_USER=postgres
DB_PASSWORD=1234
DB_PORT=5432
DB_HOST=db
```

```bash
server {
    listen 80;

    location /static/ {
        alias /static/;
    }

    location / {
        proxy_pass http://app:8000;
    }
}
```

```bash
to create a super user, exec into docker container.
docker exec -it <container-name> sh
python3 manage.py createsuperuser
```