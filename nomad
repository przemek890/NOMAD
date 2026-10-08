#!/usr/bin/env bash
# One command on every system; on Windows the same "./nomad ..." runs nomad.cmd.
#
#   ./nomad start            model, cable network to the mini PC and the bridge (also after a restart)
#   ./nomad stop             undo the cable network and the bridge
#   ./nomad status           network, mini PC address, bridge
#   ./nomad test [address]   check a running NOMAD (default: nomad.local)
#   ./nomad report [address] benchmarks into content/notes (Benchmarks, Downloaded content)
set -Eeuo pipefail

readonly HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

case ${1:-start} in
  start) exec "$HERE/network/start.sh" ;;
  stop)
    "$HERE/network/llm-bridge.sh" stop
    exec sudo "$HERE/network/link.sh" down
    ;;
  status)
    "$HERE/network/link.sh" status
    exec "$HERE/network/llm-bridge.sh" status
    ;;
  test) exec "$HERE/tests/smoke.sh" "${2:-nomad.local}" "${@:3}" ;;
  report) exec "$HERE/tests/benchmark.sh" "${2:-nomad.local}" ;;
  *)
    echo "Usage: ./nomad start|stop|status|test|report [address]" >&2
    exit 1
    ;;
esac
