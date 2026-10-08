SHELL := /bin/bash
.DEFAULT_GOAL := up

-include .env
export NOMAD_BOX_IMAGE ?= nomad-box:latest

BUILDER := nomad-builder
BAKE := docker buildx bake --file docker-bake.hcl --builder $(BUILDER) $(if $(PLATFORM),--set '*.platform=$(PLATFORM)')
BOX := docker compose exec nomad
ARCHIVE := dist/nomad-box.tar.gz
ROOT_CA := dist/nomad-root-ca.crt
CA_PATH := /data/caddy/pki/authorities/local/root.crt
URL := $(if $(NOMAD_DOMAIN),https://$(NOMAD_DOMAIN),http://localhost:$(or $(NOMAD_PORT),8080))
IP ?= 127.0.0.1

.PHONY: help init builder images box build image up down restart logs logs-admin status preload shell hosts trust export import prune clean

help: ## Show available commands
	@grep -E '^[a-z-]+:.*## ' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*## "} {printf "  \033[36m%-11s\033[0m %s\n", $$1, $$2}'

.env:
	cp .env.example .env

init: .env ## Create .env from the template

builder:
	@docker buildx inspect $(BUILDER) >/dev/null 2>&1 || docker buildx create --name $(BUILDER) --driver docker-container >/dev/null

images: builder ## Build NOMAD images into .build/images
	$(BAKE) images

box: builder ## Build the nomad-box image with the NOMAD images inside
	$(BAKE) box

build: images box ## Full build (images + box)

image:
	@docker image inspect $(NOMAD_BOX_IMAGE) >/dev/null 2>&1 || $(MAKE) --no-print-directory build prune

up: init image ## Build if needed and start NOMAD with the content from content/ (default: make)
	docker compose up --detach --wait
	@$(if $(NOMAD_DOMAIN),$(MAKE) --no-print-directory trust)
	@echo "NOMAD is running: $(URL). Content downloads in the background, progress: make logs"

down: ## Stop NOMAD (data is kept)
	docker compose down

restart: down up ## Restart NOMAD

logs: ## Follow nomad-box logs
	docker compose logs --follow

logs-admin: ## Follow Command Center logs
	$(BOX) docker logs --follow nomad_admin

status: ## Show services inside nomad-box
	$(BOX) docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

preload: ## Install content from content/ again without a restart
	$(BOX) nomad-preload

shell: ## Open a shell inside nomad-box
	$(BOX) bash

hosts: ## Print the /etc/hosts line for the domain (IP=address for other devices)
	@$(BOX) nomad-domain hosts $(IP)

ifeq ($(shell uname -s),Darwin)
trust_ca = sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $(1)
else ifneq ($(shell grep -qi microsoft /proc/version 2>/dev/null && echo wsl),)
trust_ca = cp $(1) /mnt/c/Users/Public/nomad-root-ca.crt && powershell.exe -NoProfile -Command "Start-Process certutil -Verb RunAs -Wait -ArgumentList '-addstore','-f','Root','C:\Users\Public\nomad-root-ca.crt'"
else
trust_ca = sudo cp $(1) /usr/local/share/ca-certificates/nomad-root-ca.crt && sudo update-ca-certificates
endif

trust: ## Trust the HTTPS certificate system-wide (once, asks for your password)
	@mkdir -p dist
	@for i in $$(seq 30); do docker compose cp proxy:$(CA_PATH) $(ROOT_CA).new >/dev/null 2>&1 && break; sleep 1; done
	@test -f $(ROOT_CA).new || { echo "The HTTPS proxy has not issued a certificate. Check: docker compose logs proxy"; exit 1; }
	@if cmp -s $(ROOT_CA).new $(ROOT_CA); then rm $(ROOT_CA).new; \
	else echo "Trusting the HTTPS certificate"; $(call trust_ca,$(ROOT_CA).new) && mv $(ROOT_CA).new $(ROOT_CA); fi

export: ## Save the image to dist/nomad-box.tar.gz (to move it to another machine)
	@mkdir -p dist
	docker save $(NOMAD_BOX_IMAGE) | gzip > $(ARCHIVE)

import: ## Load the image from dist/nomad-box.tar.gz
	gunzip --stdout $(ARCHIVE) | docker load

prune: ## Clear the build cache (frees several GB after make build)
	docker buildx prune --builder $(BUILDER) --all --force

clean: ## Remove the container and the inner Docker engine (data/ is kept)
	docker compose down --volumes
