#!/usr/bin/env bash
# Daily sync: iterate every project in MANIFEST.yaml. For each:
#   1. fetch origin
#   2. stash any uncommitted work (with marker), if dirty
#   3. merge origin/<branch> into local (default merge, no rebase)
#   4. unstash
#   5. commit any still-dirty state with a dated message
#   6. push
#
# Multi-machine safe: if Mac2 pushed first, this merges Mac2's commits before
# adding Mac1's. If a merge or stash-pop hits a real conflict, we surface it
# loudly in the log and skip the repo — no broken state is pushed.
#
# Usage:
#   sync-all.sh           # commit + push all repos
#   sync-all.sh --dry     # report intent; do nothing
set -uo pipefail

HUB="$(cd "$(dirname "$0")/.." && pwd)"
LOGFILE="$HUB/logs/sync.log"
STATE="$HUB/state/last-sync.txt"
mkdir -p "$HUB/logs" "$HUB/state"

DRY=0
[[ "${1:-}" == "--dry" || "${1:-}" == "-n" ]] && DRY=1

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(ts)] $*" | tee -a "$LOGFILE" >&2; }

readarray -t PROJECTS < <(python3 "$HUB/scripts/_manifest.py" | awk '{print $NF}')

STASH_TAG="archiving-sync-$(date '+%Y%m%d')"
total=0; pulled=0; merged=0; pushed=0; failed=0; skipped=0; conflict=0

for path in "${PROJECTS[@]}"; do
  total=$((total + 1))
  [[ -d "$path" ]]      || { log "SKIP missing: $path";    skipped=$((skipped + 1)); continue; }
  [[ -d "$path/.git" ]] || { log "SKIP not-a-repo: $path"; skipped=$((skipped + 1)); continue; }

  cd "$path"

  # Skip if mid-operation (merge/rebase/cherry-pick already in progress)
  for f in MERGE_HEAD REBASE_HEAD CHERRY_PICK_HEAD; do
    if [[ -f .git/$f ]]; then
      log "SKIP in-progress ($f): $path"
      skipped=$((skipped + 1)); continue 2
    fi
  done

  branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo HEAD)"
  if [[ "$branch" == "HEAD" ]]; then
    log "SKIP detached HEAD: $path"
    skipped=$((skipped + 1)); continue
  fi

  if ! git remote get-url origin >/dev/null 2>&1; then
    log "SKIP no-origin: $path  (run bootstrap-project.sh first)"
    skipped=$((skipped + 1)); continue
  fi

  # --- Dry mode: only report what's pending --------------------------------
  if [[ $DRY -eq 1 ]]; then
    dirty=$(git status --porcelain | wc -l | tr -d ' ')
    git fetch -q origin "$branch" 2>/dev/null || true
    ahead=$(git rev-list --count "origin/$branch..HEAD" 2>/dev/null || echo 0)
    behind=$(git rev-list --count "HEAD..origin/$branch" 2>/dev/null || echo 0)
    [[ $dirty -eq 0 && $ahead -eq 0 && $behind -eq 0 ]] && continue
    log "DRY: $path  dirty=$dirty ahead=$ahead behind=$behind"
    continue
  fi

  # --- Fetch + figure out divergence ---------------------------------------
  if ! git fetch -q origin "$branch" 2>>"$LOGFILE"; then
    log "FETCH-FAILED: $path ($branch)"
    failed=$((failed + 1)); continue
  fi
  behind=$(git rev-list --count "HEAD..origin/$branch" 2>/dev/null || echo 0)

  dirty_before=$(git status --porcelain | wc -l | tr -d ' ')

  # --- Stash uncommitted work if any ---------------------------------------
  stashed=0
  if (( dirty_before > 0 )); then
    if git stash push -u -q -m "$STASH_TAG" >>"$LOGFILE" 2>&1; then
      stashed=1
    else
      log "STASH-FAILED: $path  (skipping)"
      failed=$((failed + 1)); continue
    fi
  fi

  # --- Merge remote if we're behind ----------------------------------------
  if (( behind > 0 )); then
    if git -c pull.rebase=false pull --no-rebase --no-edit origin "$branch" >>"$LOGFILE" 2>&1; then
      merged=$((merged + 1))
      log "MERGED: $path  pulled $behind commit(s) from origin/$branch"
    else
      # Conflict during merge — clean up and skip
      git merge --abort >>"$LOGFILE" 2>&1 || true
      if (( stashed )); then
        git stash pop -q >>"$LOGFILE" 2>&1 || log "  WARN: could not pop stash $STASH_TAG"
      fi
      log "CONFLICT-MERGE: $path ($branch)  remote ahead by $behind; manual resolution needed"
      conflict=$((conflict + 1)); continue
    fi
    pulled=$((pulled + 1))
  fi

  # --- Pop the stash back --------------------------------------------------
  if (( stashed )); then
    if ! git stash pop -q >>"$LOGFILE" 2>&1; then
      log "CONFLICT-STASH: $path  stash $STASH_TAG kept (run \`git stash list\` to recover); skipping"
      conflict=$((conflict + 1)); continue
    fi
  fi

  # --- Commit any still-dirty state ----------------------------------------
  git add -A
  if git diff --cached --quiet; then
    # Nothing local to commit. If we pulled, push so origin sees we're in sync.
    if (( behind > 0 )); then
      if git push origin "$branch" >>"$LOGFILE" 2>&1; then
        :  # already counted as merged; no new commits to push
      fi
    fi
    continue
  fi

  msg="sync: daily archive $(date '+%Y-%m-%d')"
  if ! git -c commit.gpgsign=false commit -q -m "$msg" >>"$LOGFILE" 2>&1; then
    log "COMMIT-FAILED: $path  (likely empty diff after gitignore)"
    skipped=$((skipped + 1)); continue
  fi

  if git push origin "$branch" >>"$LOGFILE" 2>&1; then
    log "PUSHED: $path ($branch)"
    pushed=$((pushed + 1))
  else
    log "PUSH-FAILED: $path ($branch)  — retry tomorrow"
    failed=$((failed + 1))
  fi
done

summary="sync $(ts): total=$total pulled=$pulled merged=$merged pushed=$pushed conflict=$conflict failed=$failed skipped=$skipped dry=$DRY"
log "$summary"
echo "$summary" > "$STATE"

# Exit nonzero if any conflict OR push failure — launchd will surface in err log
(( conflict > 0 || failed > 0 )) && exit 3 || exit 0
