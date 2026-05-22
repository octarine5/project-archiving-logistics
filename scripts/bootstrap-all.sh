#!/usr/bin/env bash
# Driver: read MANIFEST.yaml, bootstrap projects matching a filter.
# Spawns N background workers with `& wait`. Failures are logged but don't stop the batch.
#
# Usage:
#   bootstrap-all.sh                                       # all projects, parallel=5
#   bootstrap-all.sh --only ai-code-agent,payment-system
#   bootstrap-all.sh --exclude automation-ai-agent,ml-training-platform
#   bootstrap-all.sh --parallel 1                          # serial (good for the heavy 3)
set -uo pipefail

HUB="$(cd "$(dirname "$0")/.." && pwd)"
PARALLEL=5
ONLY=""
EXCLUDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --parallel|-p) PARALLEL="$2"; shift 2 ;;
    --only)        ONLY="$2"; shift 2 ;;
    --exclude)     EXCLUDE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$HUB/logs"
RUNLOG="$HUB/logs/bootstrap-run-$(date '+%Y%m%d-%H%M%S').log"

# Read manifest as: path \t repo \t stack \t visibility
read_manifest() {
  python3 - "$HUB/MANIFEST.yaml" <<'PY'
import sys, yaml
with open(sys.argv[1]) as fh:
    data = yaml.safe_load(fh)
for p in data.get("projects", []):
    if p.get("skip"): continue
    print(f"{p['path']}\t{p['repo']}\t{p['stack']}\t{p.get('visibility','public')}")
PY
}

declare -a WORK
while IFS=$'\t' read -r path repo stack vis; do
  [[ -n "$ONLY"    && ",$ONLY,"    != *",$repo,"* ]] && continue
  [[ -n "$EXCLUDE" && ",$EXCLUDE," == *",$repo,"* ]] && continue
  WORK+=("$path|$repo|$stack|$vis")
done < <(read_manifest)

total=${#WORK[@]}
echo "[$(date '+%H:%M:%S')] running $total bootstraps with parallel=$PARALLEL"
echo "[$(date '+%H:%M:%S')] log: $RUNLOG"
[[ $total -eq 0 ]] && { echo "no work"; exit 0; }

run_one() {
  local entry="$1"
  IFS="|" read -r path repo stack vis <<<"$entry"
  if bash "$HUB/scripts/bootstrap-project.sh" "$path" "$repo" "$stack" "$vis" >> "$RUNLOG" 2>&1; then
    echo "[$(date +%H:%M:%S)] OK   $repo"
  else
    local rc=$?
    echo "[$(date +%H:%M:%S)] FAIL $repo (rc=$rc)"
  fi
}
export -f run_one
export HUB RUNLOG

# Parallel via a job-slot semaphore
declare -i running=0
for entry in "${WORK[@]}"; do
  run_one "$entry" &
  running+=1
  if (( running >= PARALLEL )); then
    wait -n
    running+=-1
  fi
done
wait

echo "[$(date '+%H:%M:%S')] batch complete — see $RUNLOG"
