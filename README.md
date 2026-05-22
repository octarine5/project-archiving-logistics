# project-archiving-logistics

The orchestration hub for archiving, syncing, and tracking the `/Users/diwang/Code/` portfolio.

It is the answer to: *"I want my code under `~/Code` uploaded and regularly synced to GitHub. I want each project bootstrapped, self-contained, and deploy-ready (matching the audit bar). I want progress tracked and reported. I want docs ready. I want artifacts — model outputs for training projects, sample I/O for services. And I want safe-to-remove projects suggested (but never auto-deleted)."*

## What's here

```
project-archiving-logitstics/
├── README.md                   ← this file
├── MANIFEST.yaml               ← canonical list of 33 archived projects (paths · repos · stack)
├── STATUS.md                   ← auto-generated portfolio dashboard
├── REMOVAL_CANDIDATES.md       ← auto-generated safe-to-remove suggestions
├── templates/
│   ├── workflows/ci-python.yml ← GitHub Actions: lint + test + Docker push to GHCR
│   ├── workflows/ci-node.yml   ← same, for Node/Next/React projects
│   ├── workflows/loadtest.yml  ← nightly locust load test → artifact CSVs
│   ├── gitignore               ← strict gitignore (venvs, model checkpoints, large binaries)
│   └── README-snippet.md       ← appended to each project's README
├── scripts/
│   ├── _manifest.py            ← shared manifest loader
│   ├── bootstrap-project.sh    ← idempotent per-project setup (git → workflows → GH repo → push)
│   ├── bootstrap-all.sh        ← parallel driver over MANIFEST.yaml
│   ├── sync-all.sh             ← daily commit-and-push across every archived repo
│   ├── status.py               ← regenerates STATUS.md
│   ├── removal-analysis.py     ← regenerates REMOVAL_CANDIDATES.md
│   └── com.octarine5.archiving.sync.plist  ← launchd job for daily sync
├── reports/                    ← dated point-in-time reports
└── logs/                       ← bootstrap.log · sync.log · launchd.{out,err}.log
```

## The audit bar (what every archived project meets)

Set by [`../AUDIT_REPORT.md`](../AUDIT_REPORT.md) + [`../COMPLETION_REPORT.md`](../COMPLETION_REPORT.md):

- `docs/` — PROPOSAL, PRODUCT, DESIGN, PERFORMANCE, SDLC
- `loadtest/` — locustfile + traffic_simulator
- `deploy/` — Dockerfile, docker-compose, k8s/deployment
- `monitoring/` — Prometheus + Grafana dashboard + observability middleware
- `Makefile` — one-command boot (`make up`, `make load`, `make k8s-up`, …)
- working app entrypoint with measured load-test numbers in PERFORMANCE.md

This hub **adds** to that bar:

- `.github/workflows/ci.yml` — lint + tests + Docker image to GHCR on every push
- `.github/workflows/loadtest.yml` — nightly locust run → CSV artifact (services only)
- `artifacts/samples/` — small, illustrative request/response or eval-output samples
- `.gitignore` — strict filters for venvs, model checkpoints, large binaries
- Origin on `github.com/octarine5/<repo>` (public) + daily auto-commit-and-push

## Common operations

```bash
# Bootstrap a single project (idempotent)
scripts/bootstrap-project.sh /Users/diwang/Code/<dir> <repo-name> <stack> public

# Bootstrap everything in MANIFEST.yaml (5-way parallel)
scripts/bootstrap-all.sh

# Just one or two:
scripts/bootstrap-all.sh --only ai-code-agent,payment-system

# Heavy ones one-at-a-time:
scripts/bootstrap-all.sh --parallel 1 --only automation-ai-agent

# Manual daily sync (dry-run first)
scripts/sync-all.sh --dry
scripts/sync-all.sh

# Regenerate reports
python3 scripts/status.py
python3 scripts/removal-analysis.py
```

## Enable the daily auto-sync (you do this, not me)

The launchd job runs `sync-all.sh` daily at **09:15 local time**, committing any uncommitted work in each archived repo with message `sync: daily archive YYYY-MM-DD` and pushing to GitHub.

```bash
# Install
cp scripts/com.octarine5.archiving.sync.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/com.octarine5.archiving.sync.plist

# Verify
launchctl list | grep com.octarine5.archiving.sync

# Trigger now (smoke test)
launchctl start com.octarine5.archiving.sync
tail -50 logs/launchd.out.log

# Disable
launchctl unload -w ~/Library/LaunchAgents/com.octarine5.archiving.sync.plist
```

Why launchd and not cron? On macOS Sequoia, launchd is the supported mechanism and survives sleep/wake correctly.

## Artifacts policy

What goes in `artifacts/samples/` (committed to git):

| Project kind | Sample contents | Size budget |
|---|---|---|
| HTTP service | request.json + response.json for each representative endpoint | <1MB each |
| CLI | input file + captured stdout/stderr | <1MB each |
| Training / ML | small eval predictions on canonical inputs (NOT checkpoints) | <1MB total |
| SPA / frontend | screenshot of the running app | <1MB |

What does **not** go in git (stays gitignored, lives in GH Releases or external storage):

- Model checkpoints (`*.pt`, `*.safetensors`, `*.gguf`, `*.onnx`)
- Datasets (`*.parquet`, `*.arrow`, `data/raw/**`)
- Training logs (`mlruns/`, `wandb/`)
- Any binary >50MB

## How removal candidates are scored

`scripts/removal-analysis.py` walks every top-level dir under `/Users/diwang/Code` and classifies into tiers:

- **Tier A** — large + stale + no recent git + not in manifest → likely safe to delete
- **Tier B** — stale but small / has git history → review before deleting
- **Tier C** — actively touched or in manifest → keep
- **Tier X** — explicit "do not touch" (notes, audio, diagrams from AUDIT_REPORT.md)

**The script never deletes anything.** Review [`REMOVAL_CANDIDATES.md`](REMOVAL_CANDIDATES.md) and remove manually.

## Tracking

- [`STATUS.md`](STATUS.md) — regenerated dashboard: per-project git/CI/origin state
- [`logs/bootstrap.log`](logs/bootstrap.log) — append-only audit trail of every bootstrap action
- [`logs/sync.log`](logs/sync.log) — append-only audit trail of every daily sync
- [`reports/`](reports/) — dated point-in-time reports captured for posterity
