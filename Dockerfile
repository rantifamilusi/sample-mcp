ARG PYTHON_BUILDER_IMAGE=python:3.12-slim
ARG PYTHON_RUNTIME_IMAGE=python:3.12-slim

FROM ${PYTHON_BUILDER_IMAGE} AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VENV_PATH=/tmp/venv

RUN ["python", "-m", "venv", "/tmp/venv"]
ENV PATH="$VENV_PATH/bin:$PATH"

RUN ["/tmp/venv/bin/python", "-m", "pip", "install", "--upgrade", "pip"]

# Install only runtime dependencies into the virtual environment.
RUN ["/tmp/venv/bin/python", "-m", "pip", "install", "--no-cache-dir", "mcp[cli]>=1.6.0", "pandas>=2.2.3", "pyarrow>=19.0.1"]


FROM ${PYTHON_RUNTIME_IMAGE} AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/tmp/venv/bin:$PATH"

WORKDIR /app

COPY --from=builder /tmp/venv /tmp/venv
COPY . /app

CMD ["python", "main.py"]