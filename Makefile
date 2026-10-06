SHELL := /bin/bash
.DEFAULT_GOAL := help

-include .env
export NOMAD_BOX_IMAGE ?= nomad-box:latest

BUILDER := nomad-builder
BAKE := docker buildx bake --file docker-bake.hcl --builder $(BUILDER) $(if $(PLATFORM),--set '*.platform=$(PLATFORM)')
BOX := docker compose exec nomad
ARCHIVE := dist/nomad-box.tar.gz
ROOT_CA := dist/nomad-root-ca.crt
IP ?= 127.0.0.1

.PHONY: help init builder images box build up down restart logs logs-admin status preload shell hosts ca trust export import prune clean

help: ## Wyświetla listę poleceń
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  \033[36m%-11s\033[0m %s\n", $$1, $$2}'

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

up: init ## Uruchamia NOMAD
	docker compose up --detach
	@echo "Pierwszy start trwa kilka minut. Postęp i adres panelu: make logs"

down: ## Zatrzymuje NOMAD (dane zostają)
	docker compose down

restart: down up ## Restart

logs: ## Logi kontenera nomad-box
	docker compose logs --follow

logs-admin: ## Logi Command Center
	$(BOX) docker logs --follow nomad_admin

status: ## Stan usług wewnątrz nomad-box
	$(BOX) docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

preload: ## Instaluje usługi, modele AI i treści zdefiniowane w .env
	$(BOX) nomad-preload

shell: ## Powłoka wewnątrz nomad-box
	$(BOX) bash

hosts: ## Wypisuje linię do /etc/hosts dla domeny (IP=adres dla innych urządzeń)
	@$(BOX) nomad-domain hosts $(IP)

ca: ## Eksportuje certyfikat lokalnego CA do dist/nomad-root-ca.crt
	@mkdir -p dist
	docker compose cp proxy:/data/caddy/pki/authorities/local/root.crt $(ROOT_CA)

trust: ca ## Dodaje lokalne CA do zaufanych w systemie (wymaga sudo)
ifeq ($(shell uname -s),Darwin)
	sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $(ROOT_CA)
else ifneq ($(shell grep -qi microsoft /proc/version 2>/dev/null && echo wsl),)
	cp $(ROOT_CA) /mnt/c/Users/Public/nomad-root-ca.crt
	powershell.exe -NoProfile -Command "Start-Process certutil -Verb RunAs -Wait -ArgumentList '-addstore','-f','Root','C:\Users\Public\nomad-root-ca.crt'"
else
	sudo cp $(ROOT_CA) /usr/local/share/ca-certificates/nomad-root-ca.crt && sudo update-ca-certificates
endif

export: ## Zapisuje obraz do dist/nomad-box.tar.gz (przeniesienie na inny komputer)
	@mkdir -p dist
	docker save $(NOMAD_BOX_IMAGE) | gzip > $(ARCHIVE)

import: ## Wczytuje obraz z dist/nomad-box.tar.gz
	gunzip --stdout $(ARCHIVE) | docker load

prune: ## Czyści cache budowania (zwalnia kilka GB po make build)
	docker buildx prune --builder $(BUILDER) --all --force

clean: ## Usuwa kontener i wewnętrzny silnik Docker (katalog data zostaje)
	docker compose down --volumes
