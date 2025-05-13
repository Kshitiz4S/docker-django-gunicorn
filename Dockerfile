FROM python:3.10-alpine

WORKDIR /app

# To stop Python from writing .pyc files at all inside the container.
ENV PYTHONDONTWRITEBYTECODE=1

# It tells Python not to buffer its output — meaning it will print everything immediately to stdout/stderr, rather than storing it temporarily (buffering) before printing.
ENV PYTHONUNBUFFERED=1

# Make sure gunicorn is present in requirements.txt file
COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

# Gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "Blog.wsgi:application"]
