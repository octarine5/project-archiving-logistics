#!/usr/bin/env bash
# Daily sync: iterate every project in MANIFEST.yaml, commit any uncommitted
# work with a dated message, and push to its GitHub remote. Designed to be
# launchd-friendly — quiet on success, loud on failure, idempotent.
#
# Usage:
#   sync-all.sh           # commit + push all dirty projects
#   sync-all.sh --dry     # report what would be committed; don't touch anything
#
# Skip rules:
#   - skips projects without origin
#   - skips merge-in-progress / rebase-in-progress states
#   - never force-pushes
set -euo pipefail

HUB="$(cd "$(dirname "$0")/.." && pwd)"
LOGFILE="$HUB/logs/sync.log"
STATE="$HUB/state/last-sync.txt"
mkdir -p "$HUB/logs" "$HUB/state"

DRY=0
[[ "${1:-}" == "--dry" || "${1:-}" == "-n" ]] && DRY=1

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(ts)] $*" | tee -a "$LOGFILE" >&2; }

readarray -t PROJECTS < <(python3 "$HUB/scripts/_manifest.py" | awk '{print $NF}')

total=0; dirty=0; pushed=0; failed=0; skipped=0

for path in "${PROJECTS[@]}"; do
  total=$((total + 1))
  [[ -d "$path" ]] || { log "SKIP missing: $path"; skipped=$((skipped + 1)); continue; }
  [[ -d "$path/.git" ]] || { log "SKIP not-a-repo: $path"; skipped=$((skipped + 1)); continue; }

  cd "$path"

  # Detect mid-operation states — don't tangle with these
  for f in MERGE_HEAD REBASE_HEAD CHERRY_PICK_HEAD; do
    if [[ -f .git/$f ]]; then
      log "SKIP in-progress ($f): $path"
      skipped=$((skipped + 1))
      continue 2
    fi
  done

  # Anything dirty?
  if [[ -z "$(git status --porcelain)" ]]; then
    continue
  fi
  dirty=$((dirty + 1))

  if [[ $DRY -eq 1 ]]; then
    files=$(git status --porcelain | wc -l | tr -d ' ')
    log "DIRTY ($files files): $path"
    continue
  fi

  branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo HEAD)"
  if [[ "$branch" == "HEAD" ]]; then
    log "SKIP detached HEAD: $path"
    skipped=$((skipped + 1))
    continue
  fi

  if ! git remote get-url origin >/dev/null 2>&1; then
    log "SKIP no-origin: $path  (run bootstrap-project.sh first)"
    skipped=$((skipped + 1))
    continue
  fi

  git add -A
  if git diff --cached --quiet; then
    continue
  fi

  msg="sync: daily archive $(date '+%Y-%m-%d')"
  if git -c commit.gpgsign=false commit -q -m "$msg"; then
    if git push origin "$branch" >>"$LOGFILE" 2>&1; then
      log "PUSHED: $path ($branch)"
      pushed=$((pushed + 1))
    else
      log "PUSH-FAILED: $path ($branch)  — see log; will retry tomorrow"
      failed=$((failed + 1))
    fi
  else
    log "COMMIT-SKIPPED: $path (likely empty diff after gitignore filtering)"
    skipped=$((skipped + 1))
  fi
done

summary="sync $(ts): total=$total dirty=$dirty pushed=$pushed failed=$failed skipped=$skipped dry=$DRY"
log "$summary"
echo "$summary" > "$STATE"

[[ $failed -gt 0 ]] && exit 3 || exit 0
