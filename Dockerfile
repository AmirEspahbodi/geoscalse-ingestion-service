# ==========================================
# STAGE 1: BUILDER (Heavyweight)
# ==========================================
FROM python:3.11-slim-bookworm as builder

# Install system build dependencies (e.g., gcc for compiling python extensions)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
ENV POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1
ENV PATH="$POETRY_HOME/bin:$PATH"
RUN pip install poetry

WORKDIR /app

# COPY dependency files FIRST to leverage Docker Layer Caching
COPY pyproject.toml poetry.lock ./

# Install dependencies
# --mount=type=cache speeds up re-builds by caching pip/poetry downloads
RUN --mount=type=cache,target=/root/.cache/pypoetry \
    poetry install --no-root --only main

# Copy source code and install the project itself
COPY . .
RUN poetry install --only main

# ==========================================
# STAGE 2: RUNTIME (Lightweight & Secure)
# ==========================================
FROM python:3.11-slim-bookworm as runtime

# Create a non-root user 'geoscale'
RUN groupadd -g 1000 geoscale && \
    useradd -u 1000 -g geoscale -s /bin/bash -m geoscale

# Set environment variables for production
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:$PATH" \
    # Point to the shared libs/ folder if needed
    PYTHONPATH="/app/src:/app/libs"

WORKDIR /app

# Copy the virtual environment from the builder stage
COPY --from=builder --chown=geoscale:geoscale /app/.venv /app/.venv
COPY --from=builder --chown=geoscale:geoscale /app/src /app/src

# Switch to non-root user
USER geoscale

# Healthcheck is handled by Docker Compose, but good to have a fallback
# (Requires curl or writing a python healthcheck script if curl isn't in slim)
# We stick to external compose healthchecks to keep image minimal.

# Default Entrypoint (Overridden in Compose, but safe default)
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
