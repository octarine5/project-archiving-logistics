#!/usr/bin/env bash
# Idempotent per-project setup:
#   1. Ensures git is initialized
#   2. Writes/merges .gitignore from template
#   3. Installs CI workflows (.github/workflows/ci.yml + loadtest.yml) sized to stack
#   4. Ensures artifacts/samples/ exists with placeholder
#   5. Appends source-control README snippet (once)
#   6. Stages + commits any changes from this bootstrap
#   7. Creates GitHub repo if missing, pushes
#
# Usage:
#   bootstrap-project.sh <project_path> <repo_name> <stack> <visibility>
#
# Re-run safe — every step is gated on "already done?".
set -euo pipefail

HUB="$(cd "$(dirname "$0")/.." && pwd)"
LOGFILE="$HUB/logs/bootstrap.log"
mkdir -p "$HUB/logs"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"; }
die() { log "ERROR: $*"; exit 1; }

[[ $# -ge 4 ]] || die "Usage: $0 <path> <repo> <stack> <visibility>"

PROJECT_PATH="$1"
REPO_NAME="$2"
STACK="$3"
VISIBILITY="$4"   # public | private

[[ -d "$PROJECT_PATH" ]] || die "Path not found: $PROJECT_PATH"

log "=== bootstrap: $REPO_NAME ($STACK, $VISIBILITY) at $PROJECT_PATH ==="

cd "$PROJECT_PATH"

# --- 1. git init -------------------------------------------------------------
if [[ ! -d .git ]]; then
  log "  git init"
  git init -q
  git checkout -q -b main 2>/dev/null || true
fi
CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo main)"

# --- 2. .gitignore -----------------------------------------------------------
TEMPLATE_GI="$HUB/templates/gitignore"
if [[ ! -f .gitignore ]]; then
  log "  writing fresh .gitignore"
  cp "$TEMPLATE_GI" .gitignore
elif ! grep -q "project-archiving-logistics" .gitignore 2>/dev/null; then
  log "  appending portfolio .gitignore (de-duped)"
  {
    echo ""
    echo "# --- appended by project-archiving-logistics ---"
    # only add lines that don't already exist in the existing .gitignore
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ ^# ]] && { echo "$line"; continue; }
      grep -Fxq "$line" .gitignore || echo "$line"
    done < "$TEMPLATE_GI"
  } >> .gitignore
fi

# --- 3. CI workflows ---------------------------------------------------------
mkdir -p .github/workflows

case "$STACK" in
  python|cli) CI_TEMPLATE="$HUB/templates/workflows/ci-python.yml" ;;
  node|spa)   CI_TEMPLATE="$HUB/templates/workflows/ci-node.yml" ;;
  polyglot)   CI_TEMPLATE="$HUB/templates/workflows/ci-python.yml" ;;   # python is primary
  shell|hub|notes|unknown) CI_TEMPLATE="$HUB/templates/workflows/ci-python.yml" ;;
  *)          CI_TEMPLATE="$HUB/templates/workflows/ci-python.yml" ;;
esac

if [[ ! -f .github/workflows/ci.yml ]]; then
  log "  installing CI workflow (template: $(basename "$CI_TEMPLATE"))"
  cp "$CI_TEMPLATE" .github/workflows/ci.yml
fi

if [[ ! -f .github/workflows/loadtest.yml ]]; then
  # Only services with an HTTP surface get the load test
  if [[ -f loadtest/locustfile.py || -f locustfile.py ]]; then
    log "  installing nightly loadtest workflow"
    cp "$HUB/templates/workflows/loadtest.yml" .github/workflows/loadtest.yml
  else
    log "  skipping loadtest workflow (no locustfile detected)"
  fi
fi

# --- 4. artifacts/samples/ ---------------------------------------------------
if [[ ! -d artifacts/samples ]]; then
  log "  creating artifacts/samples/"
  mkdir -p artifacts/samples
  cat > artifacts/samples/README.md <<'EOF'
# Sample artifacts

This directory holds **small, illustrative** artifacts that demonstrate the project's behavior end-to-end without requiring a full boot:

- **Services** — sample request/response pairs (JSON). One per representative endpoint.
- **Training / ML projects** — sample evaluation outputs, small predictions on canonical inputs, NOT model checkpoints (those go to release assets or external storage).
- **CLI tools** — sample input + captured stdout.

Keep each file <1MB. Large binaries belong in GitHub Releases or external storage, referenced here by URL.
EOF
fi

# --- 5. README snippet -------------------------------------------------------
if [[ -f README.md ]]; then
  if ! grep -q "project-archiving-logistics" README.md 2>/dev/null; then
    log "  appending source-control snippet to README.md"
    cat "$HUB/templates/README-snippet.md" >> README.md
  fi
else
  log "  README.md absent — creating stub"
  cat > README.md <<EOF
# $REPO_NAME

Portfolio project. See [\`docs/PROPOSAL.md\`](docs/PROPOSAL.md) for the business case, [\`docs/DESIGN.md\`](docs/DESIGN.md) for the architecture, and [\`docs/PERFORMANCE.md\`](docs/PERFORMANCE.md) for measured numbers.
EOF
  cat "$HUB/templates/README-snippet.md" >> README.md
fi

# --- 6. Stage + commit -------------------------------------------------------
git add -A
if ! git diff --cached --quiet; then
  if ! git rev-parse HEAD >/dev/null 2>&1; then
    log "  initial commit"
    git -c commit.gpgsign=false commit -q -m "chore: initial commit (project-archiving-logistics bootstrap)"
  else
    log "  bootstrap commit"
    git -c commit.gpgsign=false commit -q -m "chore: archiving bootstrap (CI workflows, .gitignore, artifacts dir, README snippet)"
  fi
else
  log "  nothing to commit (already bootstrapped)"
fi

# --- 7. GitHub repo + push ---------------------------------------------------
GH_OWNER="$(gh api user --jq .login 2>/dev/null || echo octarine5)"

if gh repo view "$GH_OWNER/$REPO_NAME" >/dev/null 2>&1; then
  log "  GH repo exists: $GH_OWNER/$REPO_NAME"
else
  log "  creating GH repo: $GH_OWNER/$REPO_NAME ($VISIBILITY)"
  gh repo create "$GH_OWNER/$REPO_NAME" "--$VISIBILITY" \
    --description "Portfolio: $REPO_NAME — managed by project-archiving-logistics" \
    --source . --remote origin --push=false 2>&1 | tee -a "$LOGFILE" || \
    die "gh repo create failed for $REPO_NAME"
fi

# Ensure origin is set (gh repo create --source sets it, but be defensive)
if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "https://github.com/$GH_OWNER/$REPO_NAME.git"
fi

log "  pushing $CURRENT_BRANCH -> origin"
if ! git push -u origin "$CURRENT_BRANCH" 2>&1 | tee -a "$LOGFILE"; then
  log "  initial push failed — investigate; do not force"
  exit 2
fi

log "=== done: $REPO_NAME ==="
echo "https://github.com/$GH_OWNER/$REPO_NAME"
