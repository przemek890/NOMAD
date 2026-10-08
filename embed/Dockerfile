# syntax=docker/dockerfile:1

# llama.cpp server for nomic-embed-text. The official image carries ~770 MB of packages
# it only needs to build; this one takes just the server and the libraries it links (~150 MB).
ARG LLAMA_CPP_IMAGE=ghcr.io/ggml-org/llama.cpp:server-b11459
FROM ${LLAMA_CPP_IMAGE} AS llama

FROM ubuntu:24.04
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates libgomp1 libssl3t64 \
 && rm -rf /var/lib/apt/lists/*
COPY --from=llama /app /app
WORKDIR /app
ENTRYPOINT ["/app/llama-server"]
