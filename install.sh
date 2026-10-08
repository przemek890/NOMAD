#!/usr/bin/env bash
# Installs NOMAD Box and starts it, either from a copy of the repository (./install.sh)
# or straight from GitHub (curl -fsSL .../install.sh | bash), which also updates it.
# Options (environment): NOMAD_LLM_URL (LLM server for chat), NOMAD_EMBED_URL (server for
# embeddings instead of the bundled Ollama), NOMAD_DIR (where to clone)
set -Eeuo pipefail

readonly REPO=https://github.com/przemek890/NOMAD.git
readonly OS=$(uname -s)

if [[ -f ${BASH_SOURCE[0]:-} ]]; then
  LOCAL=1
  DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
elif [[ $OS == Darwin ]]; then
  DIR=${NOMAD_DIR:-$HOME/nomad}
else
  DIR=${NOMAD_DIR:-/opt/nomad}
fi

say() {
  printf '\033[1;32m[nomad]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[nomad]\033[0m %s\n' "$*" >&2
  exit 1
}

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

install_tools() {
  if [[ $OS == Darwin ]]; then
    command -v make >/dev/null || die "Install the developer tools first: xcode-select --install"
    command -v docker >/dev/null || die "Install Docker Desktop first: https://www.docker.com/products/docker-desktop/"
    return
  fi
  command -v apt-get >/dev/null || die "Install git, make and Docker, then run this again"
  local -a missing=()
  [[ -n ${LOCAL:-} ]] || command -v git >/dev/null || missing+=(git)
  command -v make >/dev/null || missing+=(make)
  if ((${#missing[@]})); then
    say "Installing ${missing[*]}"
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}" >/dev/null
  fi
  if ! command -v docker >/dev/null; then
    is_wsl && die "Turn on WSL integration for this distribution in Docker Desktop (Settings > Resources > WSL integration)"
    say "Installing Docker"
    curl -fsSL https://get.docker.com | sudo sh >/dev/null
  fi
  if ! is_wsl && getent group docker >/dev/null && ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
  fi
}

# MySQL needs 4 KB memory pages; the default Raspberry Pi 5 kernel uses 16 KB
check_page_size() {
  [[ $OS == Linux ]] && ! is_wsl || return 0
  [[ $(getconf PAGESIZE) == 4096 ]] && return
  local config=/boot/firmware/config.txt
  [[ -f $config ]] || die "This kernel uses $(getconf PAGESIZE)-byte memory pages; MySQL needs 4 KB pages"
  grep -qx 'kernel=kernel8.img' "$config" || echo 'kernel=kernel8.img' | sudo tee -a "$config" >/dev/null
  die "Switched to the kernel with 4 KB pages. Reboot and run the same command again."
}

get_repo() {
  [[ -z ${LOCAL:-} ]] || return 0
  if [[ -d $DIR/.git ]]; then
    say "Updating ${DIR}"
    git -C "$DIR" pull --ff-only --quiet
    return
  fi
  [[ ! -e $DIR || -z $(ls -A "$DIR") ]] || die "${DIR} exists and is not NOMAD; choose another folder with NOMAD_DIR"
  say "Downloading NOMAD to ${DIR}"
  [[ -w ${DIR%/*} ]] || sudo install -d -o "$(id -u)" -g "$(id -g)" "$DIR"
  git clone --quiet "$REPO" "$DIR"
}

# HTTPS at nomad.localhost only helps a browser on the same machine (macOS, Windows)
configure() {
  local env=$DIR/.env name
  if [[ ! -f $env ]]; then
    if [[ $OS == Darwin ]] || is_wsl; then
      cp "$DIR/.env.example" "$env"
    else
      : >"$env"
    fi
  fi
  # A Linux machine is used from other devices: its name for them, e.g. for the Knowledge Search tile
  if [[ $OS == Linux ]] && ! is_wsl && ! grep -q '^NOMAD_HOST=' "$env"; then
    echo "NOMAD_HOST=$(hostname).local" >>"$env"
  fi
  for name in NOMAD_LLM_URL NOMAD_EMBED_URL; do
    [[ -n ${!name:-} ]] || continue
    { grep -v "^${name}=" "$env" || true; echo "${name}=${!name}"; } >"${env}.tmp"
    mv "${env}.tmp" "$env"
  done
}

start() {
  if docker info >/dev/null 2>&1; then
    make -C "$DIR"
  elif [[ $OS == Linux ]] && ! is_wsl; then
    sg docker -c "make -C '${DIR}'"
  else
    die "Start Docker Desktop and run this again"
  fi
  [[ $OS == Linux ]] && ! is_wsl || return 0
  say "Open http://$(hostname -I | awk '{print $1}'):8080 from another device"
}

# Everything runs from main, so "curl | bash" reads the whole script before anything uses stdin
main() {
  install_tools
  check_page_size
  get_repo
  configure
  start
}

main
