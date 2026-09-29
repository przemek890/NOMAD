# syntax=docker/dockerfile:1

FROM docker:28.5-dind

RUN apk add --no-cache bash curl jq socat

ARG NOMAD_VERSION
ARG NOMAD_ADMIN_IMAGE
ARG NOMAD_DISK_COLLECTOR_IMAGE
ARG NOMAD_MYSQL_IMAGE
ARG NOMAD_REDIS_IMAGE
ARG NOMAD_DOZZLE_IMAGE

LABEL org.opencontainers.image.title="NOMAD Box" \
      org.opencontainers.image.description="Project NOMAD for Windows, macOS and Raspberry Pi in a single Docker-in-Docker container" \
      org.opencontainers.image.version="${NOMAD_VERSION}" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV NOMAD_VERSION=${NOMAD_VERSION} \
    NOMAD_ADMIN_IMAGE=${NOMAD_ADMIN_IMAGE} \
    NOMAD_DISK_COLLECTOR_IMAGE=${NOMAD_DISK_COLLECTOR_IMAGE} \
    NOMAD_MYSQL_IMAGE=${NOMAD_MYSQL_IMAGE} \
    NOMAD_REDIS_IMAGE=${NOMAD_REDIS_IMAGE} \
    NOMAD_DOZZLE_IMAGE=${NOMAD_DOZZLE_IMAGE} \
    NOMAD_HOME=/opt/project-nomad \
    NOMAD_URL=http://localhost:8080 \
    NOMAD_HOST_OLLAMA=false \
    NOMAD_PRELOAD_SERVICES="nomad_kiwix_server nomad_ollama nomad_flatnotes nomad_cyberchef" \
    NOMAD_PRELOAD_MODELS="llama3.2:3b nomic-embed-text:v1.5" \
    NOMAD_PRELOAD_ZIMS="" \
    NOMAD_DOMAIN="" \
    NOMAD_APPS="wiki=8090 cyberchef=8100 notes=8200 kolibri=8310 pdf=8400 files=8410 books=8420 tools=8430 mesh=8450 homebox=8470 vault=https:8480 media=8490 meshcore=https:8500 logs=9999"

COPY --from=images / /opt/nomad-box/images/
COPY box/compose/ /opt/nomad-box/compose/
COPY box/lib/ /usr/local/lib/nomad-box/
COPY --chmod=0755 box/bin/ /usr/local/bin/

VOLUME ["/opt/project-nomad"]
EXPOSE 8080 8090 8100 8200 8310 9999

HEALTHCHECK --interval=30s --timeout=10s --start-period=10m --retries=3 \
  CMD curl -fsS http://localhost:8080/api/health || exit 1

ENTRYPOINT ["nomad-box"]
