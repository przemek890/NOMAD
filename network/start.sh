#!/usr/bin/env bash
# Everything the computer running the model needs for the NOMAD mini PC, in one command, on a new
# computer as well as after a restart: installs and starts Ollama, downloads the chat model and the
# embedding model once, installs Caddy, then sets up the cable network and the bridge to the model.
# Asks for your password (installing and the network need administrator rights). macOS and Linux.
#
#   network/start.sh      (./nomad start)
#
# Settings for this computer go in network/local.env (see local.env.example): CHAT_MODEL,
# OLLAMA_START, CADDY.
set -Eeuo pipefail

readonly DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=/dev/null
[[ ! -f $DIR/local.env ]] || source "$DIR/local.env"

readonly OLLAMA=http://127.0.0.1:11434
readonly CHAT_MODEL=${CHAT_MODEL:-qwen3:8b}
# The model NOMAD indexes the knowledge base with; it must be the same everywhere
readonly EMBED_MODEL=nomic-embed-text:v1.5
readonly OS=$(uname -s)

say() {
  printf '\033[1;32m[start]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[start]\033[0m %s\n' "$*" >&2
  exit 1
}

ollama_up() {
  curl -fsS -m 3 "$OLLAMA/api/version" >/dev/null 2>&1
}

need_brew() {
  command -v brew >/dev/null || die "Install Homebrew first (https://brew.sh), then run ./nomad start again"
}

install_ollama() {
  if [[ $OS == Darwin ]]; then
    [[ -d /Applications/Ollama.app ]] && return
    need_brew
    say "Installing Ollama"
    brew install --cask ollama
  elif ! command -v ollama >/dev/null; then
    say "Installing Ollama"
    curl -fsSL https://ollama.com/install.sh | sh
  fi
}

start_ollama() {
  ollama_up && return
  if [[ -n ${OLLAMA_START:-} ]]; then
    say "Starting Ollama: ${OLLAMA_START}"
    $OLLAMA_START
  else
    install_ollama
    say "Starting Ollama"
    if [[ $OS == Darwin ]]; then open -a Ollama; else sudo systemctl enable --now ollama; fi
  fi
  for _ in {1..60}; do
    ollama_up && return
    sleep 1
  done
  die "Ollama does not answer at ${OLLAMA}"
}

# Downloaded by this computer's Ollama, once; NOMAD itself never downloads models
pull_models() {
  local model models
  models=$(curl -fsS -m 10 "$OLLAMA/api/tags" | jq -r '.models[].name')
  for model in "$CHAT_MODEL" "$EMBED_MODEL"; do
    grep -qxF "$model" <<<"$models" || grep -qxF "${model}:latest" <<<"$models" && continue
    say "Downloading the model ${model} (once, a few GB)"
    curl -fsS -m 7200 "$OLLAMA/api/pull" --data "{\"model\": \"${model}\", \"stream\": false}" >/dev/null \
      || die "Could not download ${model}. Is there internet and enough disk space?"
  done
}

install_caddy() {
  [[ -n ${CADDY:-} ]] || command -v caddy >/dev/null && return
  say "Installing Caddy (the bridge to the model)"
  if [[ $OS == Darwin ]]; then
    need_brew
    brew install caddy
  else
    sudo apt-get install -y -qq caddy >/dev/null
    # Only the binary is needed, not Caddy's own web server on port 80
    sudo systemctl disable --now caddy >/dev/null 2>&1 || true
  fi
}

command -v jq >/dev/null || die "Install jq first (macOS: brew install jq, Linux: sudo apt install jq)"
start_ollama
pull_models
install_caddy
sudo "$DIR/link.sh" up
"$DIR/llm-bridge.sh" start
"$DIR/link.sh" status
say "Chat model: ${CHAT_MODEL}. NOMAD: http://nomad.local:8080"
