---
name: docker-patterns
description: Docker and Docker Compose patterns for Python development — multi-service local stacks (app, Postgres, Redis, Celery), multi-stage Dockerfiles, and container security. Use when dockerizing a Python app, setting up or editing docker-compose for local development, or debugging container builds.
origin: ECC
---

# Docker Patterns for Python

Docker and Docker Compose for local Python/Django/FastAPI development. The core reference is the multi-service **Compose stack** below (app + Postgres + Redis + Celery + celery-beat); the Dockerfile supports it by defining the `runner` target the stack builds from.

## When to Activate

- Setting up a local multi-service stack with Docker Compose
- Dockerizing a Python app (multi-stage build, non-root user, healthcheck)
- Designing multi-container architectures

## Python Dockerfile (Multi-Stage)

Defines the `runner` target that the Compose stack builds from.

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install --no-cache-dir uv
COPY requirements.txt .
RUN uv pip install --system --no-cache -r requirements.txt

FROM python:3.12-slim AS runner
WORKDIR /app
RUN useradd -r -u 1001 appuser
USER appuser
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . .
ENV PYTHONUNBUFFERED=1
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/')" || exit 1
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4"]
```

## Docker Compose for Python Stack

```yaml
services:
  app:
    build:
      context: .
      target: runner
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/app_dev
      - REDIS_URL=redis://redis:6379/0
      - DJANGO_SETTINGS_MODULE=config.settings.development
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    command: python manage.py runserver 0.0.0.0:8000

  db:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: app_dev
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  celery:
    build: .
    command: celery -A config worker -l info
    volumes:
      - .:/app
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/app_dev
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - db
      - redis

  celery-beat:
    build: .
    command: celery -A config beat -l info
    volumes:
      - .:/app
    depends_on:
      - redis

volumes:
  pgdata:
```

## Security

```yaml
services:
  app:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
```

## Common Commands

```bash
docker compose up                    # Start
docker compose logs -f app           # Follow logs
docker compose exec app python manage.py shell  # Django shell
docker compose exec db psql -U postgres          # Postgres shell
docker compose down -v               # Stop and remove volumes
```
