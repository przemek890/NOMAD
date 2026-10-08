#!/usr/bin/env bash
# Makes the local Ollama reachable for the mini PC, only on the cable (10.77.0.1:11434).
# Ollama itself keeps listening on 127.0.0.1 only; this bridge passes through
# just the endpoints NOMAD's chat and embeddings need (no pulling or deleting models).
# macOS and Linux (needs Caddy); Windows: link.ps1 bridge-start
#
#   network/llm-bridge.sh start|stop|status
#
# Settings (network/local.env or environment): CADDY (default: caddy on PATH),
# OLLAMA_URL (default 127.0.0.1:11434)
set -Eeuo pipefail

readonly HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=/dev/null
[[ ! -f $HERE/local.env ]] || source "$HERE/local.env"

readonly LINK_IP=10.77.0.1
readonly PORT=11434
readonly DIR=$HERE/.run
readonly CONFIG=$DIR/llm-bridge.caddyfile
readonly PIDFILE=$DIR/llm-bridge.pid
readonly LOGFILE=$DIR/llm-bridge.log
readonly UPSTREAM=${OLLAMA_URL:-127.0.0.1:11434}
readonly CADDY=${CADDY:-$(command -v caddy || true)}

say() {
  printf '\033[1;32m[llm-bridge]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[llm-bridge]\033[0m %s\n' "$*" >&2
  exit 1
}

running() {
  [[ -s $PIDFILE ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

write_config() {
  cat >"$CONFIG" <<EOF
{
	admin off
	auto_https off
	persist_config off
}

http://:${PORT} {
	bind ${LINK_IP}
	@read {
		method GET
		path /v1/models /api/tags /api/version /api/ps
	}
	@inference {
		method POST
		path /v1/chat/completions /v1/completions /api/chat /api/generate /api/show /api/embed /api/embeddings /v1/embeddings
	}
	handle @read {
		reverse_proxy ${UPSTREAM} {
			header_up Host ${UPSTREAM}
		}
	}
	handle @inference {
		request_body {
			max_size 16MB
		}
		reverse_proxy ${UPSTREAM} {
			header_up Host ${UPSTREAM}
			flush_interval -1
		}
	}
	handle {
		respond "Endpoint disabled" 403
	}
}
EOF
}

start() {
  running && { say "Already running: http://${LINK_IP}:${PORT}"; return; }
  [[ -x $CADDY ]] || die "Caddy not found. Install it (https://caddyserver.com/docs/install) or set CADDY in network/local.env"
  { ifconfig 2>/dev/null || ip -4 addr; } | grep -q "inet ${LINK_IP}[ /]" || die "No ${LINK_IP} here. First: sudo network/link.sh up"
  curl -fsS -m 3 "http://${UPSTREAM}/api/version" >/dev/null \
    || die "Ollama does not answer at ${UPSTREAM}. Start Ollama first"
  mkdir -p "$DIR"
  write_config
  nohup "$CADDY" run --config "$CONFIG" --adapter caddyfile >"$LOGFILE" 2>&1 &
  echo $! >"$PIDFILE"
  for _ in {1..20}; do
    curl -fsS -m 2 "http://${LINK_IP}:${PORT}/api/version" >/dev/null 2>&1 && break
    sleep 0.5
  done
  running || die "Bridge did not start, see ${LOGFILE}"
  say "Model available to the mini PC: http://${LINK_IP}:${PORT}"
}

stop() {
  if running; then
    kill "$(cat "$PIDFILE")"
    say "Stopped"
  fi
  rm -f "$PIDFILE"
}

status() {
  if running; then
    echo "running: http://${LINK_IP}:${PORT} (pid $(cat "$PIDFILE"))"
    curl -fsS -m 3 "http://${LINK_IP}:${PORT}/api/tags" | jq -r '.models[].name' 2>/dev/null | sed 's/^/  model: /' || true
  else
    echo "stopped"
  fi
}

case ${1:-} in
  start) start ;;
  stop) stop ;;
  status) status ;;
  *) die "Usage: $0 start|stop|status" ;;
esac
