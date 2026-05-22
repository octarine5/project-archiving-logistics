#!/usr/bin/env bash
# Pre-flight check for heavy repos: apply the strict .gitignore, then report
# what would be staged AND flag any file > 50MB. Refuses to proceed if any
# large file would land in the commit.
#
# Usage:
#   preflight-heavy.sh <project_path>
set -euo pipefail

HUB="$(cd "$(dirname "$0")/.." && pwd)"
PROJ="${1:?usage: $0 <project_path>}"
[[ -d "$PROJ" ]] || { echo "missing: $PROJ" >&2; exit 1; }

cd "$PROJ"

# Ensure .git
[[ -d .git ]] || git init -q

# Apply gitignore (same merge logic as bootstrap-project.sh)
TEMPLATE_GI="$HUB/templates/gitignore"
if [[ ! -f .gitignore ]]; then
  cp "$TEMPLATE_GI" .gitignore
elif ! grep -q "project-archiving-logistics" .gitignore 2>/dev/null; then
  {
    echo ""
    echo "# --- appended by project-archiving-logistics ---"
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ ^# ]] && { echo "$line"; continue; }
      grep -Fxq "$line" .gitignore || echo "$line"
    done < "$TEMPLATE_GI"
  } >> .gitignore
fi

# Find files >50MB that would still be staged (after gitignore)
echo "==> scanning for files >50MB that would be committed..."
big=0
while IFS= read -r f; do
  if [[ -f "$f" ]]; then
    sz=$(stat -f "%z" "$f" 2>/dev/null || stat -c "%s" "$f" 2>/dev/null || echo 0)
    if (( sz > 50000000 )); then
      printf "  %sMB  %s\n" "$((sz/1000000))" "$f"
      big=$((big+1))
    fi
  fi
done < <(git ls-files --others --cached --exclude-standard)

if (( big > 0 )); then
  echo ""
  echo "❌ $big large file(s) would be committed. Add to .gitignore and re-run."
  echo "   Hint: append the offending paths or globs to .gitignore, then:"
  echo "     git rm -r --cached --ignore-unmatch <path>"
  exit 1
fi

# Count what would be staged
to_stage=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')
tracked=$(git ls-files | wc -l | tr -d ' ')
echo "✅ no >50MB offenders"
echo "   tracked:       $tracked"
echo "   to-stage-new:  $to_stage"
echo "   ready: run bootstrap-project.sh"
