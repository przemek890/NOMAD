#!/usr/bin/env bash
# Everything the computer running the model needs for the NOMAD mini PC, in one command
# (e.g. after a restart): the model (Ollama), the cable network and the bridge to the model.
# Asks for your password once (the network needs administrator rights). macOS and Linux.
#
#   network/start.sh
#
# Options (environment): OLLAMA_START (command that starts Ollama when it is not running;
# default: ~/Documents/LocalModel/scripts/start.sh if it exists)
set -Eeuo pipefail

readonly DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly LOCALMODEL_START=${LOCALMODEL_DIR:-$HOME/Documents/LocalModel}/scripts/start.sh

say() {
  printf '\033[1;32m[start]\033[0m %s\n' "$*"
}

if ! curl -fsS -m 3 http://127.0.0.1:11434/api/version >/dev/null 2>&1; then
  start=${OLLAMA_START:-}
  [[ -n $start || ! -x $LOCALMODEL_START ]] || start=$LOCALMODEL_START
  if [[ -n $start ]]; then
    say "Starting the model: ${start}"
    $start
  else
    say "Ollama is not running at 127.0.0.1:11434; start it, the mini PC gets the model then"
  fi
fi

sudo "$DIR/link.sh" up
"$DIR/llm-bridge.sh" start
"$DIR/link.sh" status
say "NOMAD: http://nomad.local:8080"
