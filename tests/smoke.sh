#!/usr/bin/env bash
# Checks a running NOMAD Box from the outside, the way a user would use it.
# Needs curl and jq. Run on the NOMAD machine or on another device:
#
#   tests/smoke.sh                 # NOMAD on this machine
#   tests/smoke.sh nomad.local     # NOMAD on the mini PC
#   tests/smoke.sh nomad.local --benchmark   # also the system benchmark (~5 min)
set -uo pipefail

readonly HOST=${1:-localhost}
readonly NOMAD=http://${HOST}:${NOMAD_PORT:-8080}
readonly SEARCH=http://${HOST}:${NOMAD_SEARCH_PORT:-8070}
readonly KIWIX=http://${HOST}:8090
readonly NOTES=http://${HOST}:8200
FAILED=0

pass() {
  printf '\033[1;32m  ok\033[0m  %s\n' "$*"
}

fail() {
  printf '\033[1;31mFAIL\033[0m  %s\n' "$*"
  FAILED=$((FAILED + 1))
}

# check "what" command...: passes when the command succeeds; its output is shown
check() {
  local what=$1 out
  shift
  if out=$("$@" 2>&1); then pass "${what}${out:+: $out}"; else fail "${what}${out:+: $out}"; fi
}

get() {
  curl -fsS -m "${2:-20}" "$1"
}

command_center() {
  get "$NOMAD/api/health" | jq -er '.status == "ok"' >/dev/null
}

internet() {
  [[ $(get "$NOMAD/api/system/internet-status") == true ]] || { echo "no internet (offline use still works)"; return 1; }
}

system_info() {
  get "$NOMAD/api/system/info" | jq -er '"CPU \(.currentLoad.currentLoad | floor)%, RAM \(.mem.active / 1e9 * 10 | floor / 10)/\(.mem.total / 1e9 * 10 | floor / 10) GB"'
}

# At least 2 GB free where NOMAD keeps its content
disk() {
  get "$NOMAD/api/system/info" | jq -er '.fsSize[] | select(.mount == "/app/storage")
    | "\(.available / 1e9 * 10 | floor / 10) GB free of \(.size / 1e9 | floor) GB" as $text
    | if .available > 2e9 then $text else error($text) end'
}

# A Wikipedia in the library answers a full-text search (no AI involved)
library() {
  local book
  book=$(get "$KIWIX/catalog/v2/entries?count=100" | grep -o 'href="/content/wikipedia[^"]*"' | cut -d/ -f3 | tr -d '"' | sort -r | head -1)
  [[ -n $book ]] || { echo "no Wikipedia in the library"; return 1; }
  get "$KIWIX/search?content=${book}&pattern=Warszawa" | grep -q "href=\"/content/${book}/" || { echo "no results in ${book}"; return 1; }
  echo "$book"
}

# Each map file NOMAD offers is served (PMTiles files start with "PMTiles")
maps() {
  local url names=()
  for url in $(get "$NOMAD/api/maps/styles" | jq -r '.sources[].url | select(startswith("pmtiles://")) | ltrimstr("pmtiles://")'); do
    [[ $(curl -fsS -m 20 -r 0-6 "$url") == PMTiles ]] || { echo "${url##*/} is not served"; return 1; }
    names+=("${url##*/}")
  done
  ((${#names[@]})) || { echo "no maps"; return 1; }
  echo "${names[*]}"
}

downloaded_note() {
  get "$NOTES/api/notes/Downloaded%20content" | jq -er '.content | select(test("## Library")) | "lists \([scan("\\.zim ")] | length) library files"'
}

ai_connected() {
  get "$NOMAD/api/ollama/remote-status" | jq -er 'select(.connected) | "connected"'
}

# The chat model answers from the knowledge base (NHS medicines are indexed by default)
ai_answer() {
  local model answer
  model=$(get "$NOMAD/api/ollama/installed-models" | jq -r '[.[].name | select(contains("embed") | not)][0] // empty')
  [[ -n $model ]] || { echo "no chat model"; return 1; }
  answer=$(curl -fsS -m 300 "$NOMAD/api/ollama/chat" -H 'Content-Type: application/json' --data "$(jq -cn --arg m "$model" \
    '{model: $m, stream: false, think: false, messages: [{role: "user",
      content: "According to the NHS, what should I do if I miss a dose of warfarin? One sentence."}]}')" \
    | jq -r '.message.content // empty')
  [[ $answer == *[Dd]ose* ]] || { echo "unexpected answer: ${answer:0:120}"; return 1; }
  echo "${model}: ${answer:0:120}"
}

# Knowledge Search finds the right passage without the chat model
knowledge_search() {
  get "$SEARCH/api/search?q=missed%20dose%20of%20warfarin&limit=3" 60 \
    | jq -er '.results[0] | select(.score > 0.5) | "\(.score) \(.title[0:70])"'
}

# Runs the system benchmark and waits for a new result (the job id differs from the result id)
benchmark() {
  local before latest
  before=$(get "$NOMAD/api/benchmark/results/latest" | jq -r '.result.benchmark_id // empty')
  curl -fsS -m 30 -X POST "$NOMAD/api/benchmark/run/system" >/dev/null || return 1
  for _ in $(seq 60); do
    sleep 10
    latest=$(get "$NOMAD/api/benchmark/results/latest" | jq -c '.result // empty')
    if [[ -n $latest && $(jq -r '.benchmark_id' <<<"$latest") != "$before" ]]; then
      jq -r '"NOMAD score \(.nomad_score)"' <<<"$latest"
      return 0
    fi
  done
  echo "no result after 10 min"
  return 1
}

echo "NOMAD at ${NOMAD}"
check "Command Center" command_center
check "Internet" internet
check "System (CPU, RAM)" system_info
check "Disk" disk
check "Library: Wikipedia full-text search" library
check "Maps" maps
check "Notes: Downloaded content" downloaded_note
check "Knowledge Search (no chat model)" knowledge_search
if ai_connected >/dev/null 2>&1; then
  check "AI: chat model" ai_connected
  check "AI: answer from the knowledge base" ai_answer
else
  fail "AI: chat model not connected (is the computer running the model on and start.sh run?)"
fi
[[ ${2:-} != --benchmark ]] || check "Benchmark" benchmark

((FAILED == 0)) && echo "All checks passed" || echo "${FAILED} check(s) failed"
exit $((FAILED > 0))
