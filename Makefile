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

help: ## Wyświetla listę poleceń
	@grep -E '^[a-z-]+:.*## ' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*## "} {printf "  \033[36m%-11s\033[0m %s\n", $$1, $$2}'

.env:
	cp .env.example .env

init: .env ## Tworzy plik .env z szablonu

builder:
	@docker buildx inspect $(BUILDER) >/dev/null 2>&1 || docker buildx create --name $(BUILDER) --driver docker-container >/dev/null

images: builder ## Buduje obrazy NOMAD do .build/images (PLATFORM=linux/arm64 dla innej architektury)
	$(BAKE) images

box: builder ## Buduje obraz nomad-box z gotowymi obrazami w środku
	$(BAKE) box

build: images box ## Pełna budowa (images + box)

image:
	@docker image inspect $(NOMAD_BOX_IMAGE) >/dev/null 2>&1 || $(MAKE) build

up: init image ## Buduje (jeśli trzeba) i uruchamia NOMAD z treściami z content/ (domyślne polecenie: make)
	docker compose up --detach --wait
	@$(if $(NOMAD_DOMAIN),$(MAKE) --no-print-directory trust)
	@echo "NOMAD działa: $(URL). Treści pobierają się w tle, postęp: make logs"

down: ## Zatrzymuje NOMAD (dane zostają)
	docker compose down

restart: down up ## Restart

logs: ## Logi kontenera nomad-box
	docker compose logs --follow

logs-admin: ## Logi Command Center
	$(BOX) docker logs --follow nomad_admin

status: ## Stan usług wewnątrz nomad-box
	$(BOX) docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

preload: ## Ponownie instaluje treści z content/ bez restartu
	$(BOX) nomad-preload

shell: ## Powłoka wewnątrz nomad-box
	$(BOX) bash

hosts: ## Wypisuje linię do /etc/hosts dla domeny (IP=adres dla innych urządzeń)
	@$(BOX) nomad-domain hosts $(IP)

ifeq ($(shell uname -s),Darwin)
trust_ca = sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $(1)
else ifneq ($(shell grep -qi microsoft /proc/version 2>/dev/null && echo wsl),)
trust_ca = cp $(1) /mnt/c/Users/Public/nomad-root-ca.crt && powershell.exe -NoProfile -Command "Start-Process certutil -Verb RunAs -Wait -ArgumentList '-addstore','-f','Root','C:\Users\Public\nomad-root-ca.crt'"
else
trust_ca = sudo cp $(1) /usr/local/share/ca-certificates/nomad-root-ca.crt && sudo update-ca-certificates
endif

trust: ## Dodaje certyfikat HTTPS do zaufanych w systemie (tylko raz, poprosi o hasło)
	@mkdir -p dist
	@for i in $$(seq 30); do docker compose cp proxy:$(CA_PATH) $(ROOT_CA).new >/dev/null 2>&1 && break; sleep 1; done
	@test -f $(ROOT_CA).new || { echo "Proxy HTTPS nie wystawił certyfikatu. Sprawdź: docker compose logs proxy"; exit 1; }
	@if cmp -s $(ROOT_CA).new $(ROOT_CA); then rm $(ROOT_CA).new; \
	else echo "Dodawanie certyfikatu HTTPS do zaufanych"; $(call trust_ca,$(ROOT_CA).new) && mv $(ROOT_CA).new $(ROOT_CA); fi

export: ## Zapisuje obraz do dist/nomad-box.tar.gz (przeniesienie na inny komputer)
	@mkdir -p dist
	docker save $(NOMAD_BOX_IMAGE) | gzip > $(ARCHIVE)

import: ## Wczytuje obraz z dist/nomad-box.tar.gz
	gunzip --stdout $(ARCHIVE) | docker load

prune: ## Czyści cache budowania (zwalnia kilka GB po make build)
	docker buildx prune --builder $(BUILDER) --all --force

clean: ## Usuwa kontener i wewnętrzny silnik Docker (katalog data zostaje)
	docker compose down --volumes
