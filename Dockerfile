# 标准单实例容器构建文件（配合本仓库的 docker-compose.yml 使用：docker compose up -d --build）
ARG PYTHON_IMAGE=python:3.12-slim

FROM ${PYTHON_IMAGE} AS builder

ARG PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/
ARG UV_VERSION=0.10.2
ENV PIP_INDEX_URL=${PIP_INDEX_URL} \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    UV_DEFAULT_INDEX=${PIP_INDEX_URL} \
    UV_NO_CACHE=1 \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/opt/venv

RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && pip install "uv==${UV_VERSION}"

WORKDIR /build
COPY pyproject.toml ./
RUN uv venv /opt/venv && uv sync --no-dev --no-install-project

FROM ${PYTHON_IMAGE} AS runtime

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH=/opt/venv/bin:$PATH \
    JIANSHANAGENT_CONFIG_DIR=/app/config

RUN useradd --create-home --uid 10001 jianshanagent \
    && mkdir -p /app /data \
    && chown -R jianshanagent:jianshanagent /app /data

COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
COPY --chown=jianshanagent:jianshanagent config ./config
COPY --chown=jianshanagent:jianshanagent sites ./sites
COPY --chown=jianshanagent:jianshanagent plugins ./plugins

USER jianshanagent
EXPOSE 8080
VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=3).read()"]

CMD ["jianshanagent"]
