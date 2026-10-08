readonly COMPOSE_FILE=/opt/nomad-box/compose/nomad.yaml
readonly IMAGES_DIR=/opt/nomad-box/images
readonly SECRETS_FILE="${NOMAD_HOME}/secrets.env"
readonly API_URL=http://localhost:8080/api
# LLM router: the bundled Ollama (nomad_ollama) computes embeddings, chat goes to NOMAD_OLLAMA_URL
readonly LLM_ROUTER_PORT=11435
readonly LLM_ROUTER_URL="http://host.docker.internal:${LLM_ROUTER_PORT}"
readonly LLM_ROUTER_LOCAL="http://127.0.0.1:${LLM_ROUTER_PORT}"
readonly EMBED_OLLAMA=http://127.0.0.1:11434
readonly EMBED_MODEL=nomic-embed-text:v1.5

: "${NOMAD_URL:=${NOMAD_DOMAIN:+https://${NOMAD_DOMAIN}}}"
export NOMAD_URL=${NOMAD_URL:-http://localhost:8080}

log() {
  printf '\033[1;32m[nomad-box]\033[0m %s\n' "$*"
}

fail() {
  printf '\033[1;31m[nomad-box]\033[0m %s\n' "$*" >&2
  exit 1
}

wait_for() {
  local seconds=$1
  shift
  local deadline=$((SECONDS + seconds))
  until "$@" >/dev/null 2>&1; do
    ((SECONDS < deadline)) || return 1
    sleep 1
  done
}

stack() {
  docker compose -p project-nomad -f "$COMPOSE_FILE" --env-file "$SECRETS_FILE" "$@"
}

api() {
  local method=$1 path=$2
  shift 2
  curl -fsS -X "$method" -H 'Content-Type: application/json' "${API_URL}${path}" "$@"
}

json() {
  jq -cn "$@"
}

db_query() {
  docker exec -e MYSQL_PWD="$NOMAD_DB_PASSWORD" nomad_mysql \
    mysql --user=nomad_user --database=nomad --batch --skip-column-names --execute="$1"
}
