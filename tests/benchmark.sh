#!/usr/bin/env bash
# Measures a running NOMAD and writes the results into the repository notes (shown in Notes too):
# the results section of content/notes/Benchmarks.md and content/notes/Downloaded content.md.
# Takes ~10 min (the system benchmark alone ~5). Needs curl and jq.
#
#   tests/benchmark.sh [address]     (./nomad report [address])
set -Eeuo pipefail
export LC_ALL=C

readonly HOST=${1:-nomad.local}
readonly NOMAD=http://${HOST}:${NOMAD_PORT:-8080}
readonly SEARCH=http://${HOST}:${NOMAD_SEARCH_PORT:-8070}
readonly NOTES=http://${HOST}:8200
# The chat model as NOMAD reaches it (the bridge on the cable); Ollama API
readonly LLM=${NOMAD_LLM_URL:-http://10.77.0.1:11434}
readonly NOTES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../content/notes" && pwd)
readonly BENCHMARKS=$NOTES_DIR/Benchmarks.md

# Chat questions: question|regular expression the answer must match (case-insensitive)
readonly QUESTIONS=(
  "According to the NHS, what should I do if I miss a dose of warfarin?|next day|as soon as you remember"
  "What is the first aid for a snake bite in the field?|immobili|still|hospital|medical"
  "How do you recognise and treat heat stroke?|cool|water|shade"
  "Co zrobić, gdy pominę dawkę warfaryny? Odpowiedz po polsku.|dawk|lekarz|przypomn"
  "Jaka jest stolica Polski i jaka rzeka przez nią płynie?|Warszaw.*Wisł|Wisł.*Warszaw"
  "Kto jest dyrektorem 1 LO w Tarnowie? Odpowiedz jednym zdaniem.|Dulęba"
)
# Knowledge Search questions (no chat model)
readonly SEARCHES=("missed dose of warfarin" "snake bite first aid" "heat stroke treatment" "water purification")

say() {
  printf '\033[1;32m[benchmark]\033[0m %s\n' "$*" >&2
}

get() {
  curl -fsS -m "${2:-30}" "$1"
}

# Runs NOMAD's system benchmark and prints its result once a new one appears. (NOMAD's own AI
# benchmark always downloads llama3.1:8b, 6.5 GB, onto the NOMAD machine; llm_speed measures the real model.)
nomad_benchmark() {
  local type=$1 before result
  before=$(get "$NOMAD/api/benchmark/results" | jq -r --arg t "$type" '[.results[] | select(.benchmark_type == $t)][0].benchmark_id // ""')
  curl -fsS -m 30 -X POST "$NOMAD/api/benchmark/run/${type}" >/dev/null
  for _ in $(seq 90); do
    sleep 10
    result=$(get "$NOMAD/api/benchmark/results" | jq -c --arg t "$type" '[.results[] | select(.benchmark_type == $t)][0] // empty')
    if [[ -n $result && $(jq -r '.benchmark_id' <<<"$result") != "$before" ]]; then
      echo "$result"
      return
    fi
  done
  echo '{}'
}

chat_model() {
  get "$NOMAD/api/ollama/installed-models" | jq -r '[.[].name | select(contains("embed") | not)][0] // empty'
}

# | model | tokens/s | time to first token | model load |: one 256-token answer
llm_speed() {
  curl -fsS -m 600 "$LLM/api/generate" --data "$(jq -cn --arg m "$1" '{model: $m, stream: false, think: false,
    prompt: "Explain in about 200 words how to purify water in the wild.", options: {num_predict: 256}}')" \
    | jq -r --arg m "$1" '"| \($m) | \(.eval_count / (.eval_duration / 1e9) * 10 | round / 10) | \((.load_duration + .prompt_eval_duration) / 1e6 | round) ms | \(.load_duration / 1e9 * 10 | round / 10) s |"'
}

# | question | seconds | ok? | start of the answer |
ask() {
  local model=$1 question=${2%%|*} pattern=${2#*|} reply seconds answer
  # Streamed with tools, as on NOMAD's chat page
  reply=$(curl -sS -N -m 600 -w '\n%{time_total}' "$NOMAD/api/ollama/chat" -H 'Content-Type: application/json' \
    --data "$(jq -cn --arg m "$model" --arg q "$question" '{model: $m, stream: true, think: false, messages: [{role: "user", content: $q}]}')")
  seconds=${reply##*$'\n'}
  answer=$(sed -n 's/^data: //p' <<<"${reply%$'\n'*}" | jq -rj '.message.content // empty' 2>/dev/null | tr '\n|' '  ')
  answer=${answer:-(no answer)}
  printf '| %s | %.0f s | %s | %s… |\n' "$question" "$seconds" \
    "$(grep -qiE "$pattern" <<<"$answer" && echo ✅ || echo ❌)" "${answer:0:160}"
}

# | question | seconds | best passage | match |
find_passage() {
  local reply seconds
  reply=$(curl -sS -m 120 -w '\n%{time_total}' -G "$SEARCH/api/search" --data-urlencode "q=$1" --data limit=1)
  seconds=${reply##*$'\n'}
  jq -r --arg q "$1" --arg s "$seconds" \
    '.results[0] // {} | "| \($q) | \($s | tonumber * 10 | round / 10) s | \(.title // "-" | gsub("[\\n|]"; " ")) | \((.score // 0) * 100 | round)% |"' \
    <<<"${reply%$'\n'*}"
}

results() {
  local system model online info
  say "System benchmark (CPU, RAM, disk), ~5 min"
  system=$(nomad_benchmark system)
  model=$(chat_model)
  online=$(get "$NOMAD/api/system/internet-status")
  info=$(get "$NOMAD/api/system/info")

  printf '## Ostatnie wyniki\n\n'
  printf 'Zmierzone %s na `%s`, internet: %s. Polecenie: `./nomad report`.\n\n' \
    "$(date '+%Y-%m-%d %H:%M')" "$HOST" "$([[ $online == true ]] && echo jest || echo brak)"
  jq -r '"Sprzęt: \(.cpu.brand), \(.cpu.cores) rdzenie, RAM \(.mem.total / 1e9 * 10 | round / 10) GB (zajęte \(.mem.active / 1e9 * 10 | round / 10) GB), obciążenie CPU \(.currentLoad.currentLoad | round)%.\n"' <<<"$info"

  printf '### System (benchmark NOMAD)\n\n'
  printf '| NOMAD score | CPU 1 wątek | CPU wszystkie wątki | RAM | Dysk odczyt | Dysk zapis |\n|---|---|---|---|---|---|\n'
  jq -r '"| \(.nomad_score // "-") | \(.cpu_events_single // "-") zdarzeń/s | \(.cpu_events_multi // "-") zdarzeń/s | \((.memory_ops_per_sec // 0) / 1e6 * 10 | round / 10) mln op/s | \(.disk_read_mb_per_sec // "-") MB/s | \(.disk_write_mb_per_sec // "-") MB/s |"' <<<"$system"

  say "AI speed (${model})"
  printf '\n### AI: szybkość modelu\n\n| Model | Tokeny/s | Czas do pierwszego tokenu | Ładowanie modelu |\n|---|---|---|---|\n'
  llm_speed "$model" || echo "| ${model} | - | - | - |"

  printf '\n### AI: poprawność odpowiedzi (czat z bazą wiedzy, model `%s`)\n\n' "$model"
  printf '| Pytanie | Czas | Poprawna | Odpowiedź |\n|---|---|---|---|\n'
  local question
  for question in "${QUESTIONS[@]}"; do
    say "Chat: ${question%%|*}"
    ask "$model" "$question"
  done

  printf '\n### Wyszukiwanie w bazie wiedzy bez AI (Knowledge Search)\n\n'
  printf '| Pytanie | Czas | Najlepszy fragment | Dopasowanie |\n|---|---|---|---|\n'
  for question in "${SEARCHES[@]}"; do
    find_passage "$question"
  done
}

# Replaces everything after the results marker in Benchmarks.md
write_results() {
  local marker='<!-- results: written by ./nomad report, do not edit below -->'
  grep -qxF "$marker" "$BENCHMARKS" || { echo "No results marker in ${BENCHMARKS}" >&2; exit 1; }
  { sed "/^$(sed 's/[][\.*^$/]/\\&/g' <<<"$marker")\$/q" "$BENCHMARKS"; echo; cat; } >"${BENCHMARKS}.tmp"
  mv "${BENCHMARKS}.tmp" "$BENCHMARKS"
}

say "NOMAD at ${NOMAD}"
get "$NOTES/api/notes/Downloaded%20content" | jq -r '.content' >"$NOTES_DIR/Downloaded content.md"
say "Updated content/notes/Downloaded content.md"
results | write_results
say "Updated content/notes/Benchmarks.md"
