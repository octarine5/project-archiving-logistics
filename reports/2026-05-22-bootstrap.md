# Bootstrap report — 2026-05-22

## Outcome

| Tier | Count | Result |
|---|---|---|
| Smoke test (tech-blog) | 1 | ✅ pushed |
| Tier 1 — small/medium projects (parallel ×5) | 28 | ✅ all pushed |
| Tier 2 — heavyweights (serial) | 3 of 3 | ✅ ml-training-platform · automation-ai-agent · leverage-work-prototypes-drill (after ~4.9 GB reclaim) |
| Hub itself | 1 | ✅ pushed |
| **Total** | **33 of 33** | **100% complete** |

## What each pushed repo got

- `.github/workflows/ci.yml` — lint + tests + Docker image to GHCR
- `.github/workflows/loadtest.yml` — nightly locust (services only — projects with a `loadtest/locustfile.py`)
- `artifacts/samples/` directory with policy README
- Strict `.gitignore` filtering venvs, model checkpoints, large binaries
- Source-control snippet appended to existing README
- `origin` pointing at `github.com/octarine5/<repo>` (public)

## Disk-full incident (resolved)

The first attempt at `leverage_work_prototypes_drill` (1.6GB, 20,432 files) hit ENOSPC mid-`git add` because automation_ai_agent's pack write had pushed the disk to 100%. Resolution:

1. User ran the 4 reclaim commands from REMOVAL_CANDIDATES.md (~4.9 GB freed)
2. The partial `/Users/diwang/Code/leverage_work_prototypes_drill/.git` was removed
3. `bash scripts/bootstrap-all.sh --parallel 1 --only leverage-work-prototypes-drill` succeeded in 22s

Lesson: bootstrap order matters when disk is tight — bootstrap the smallest projects first (their packs compact quickly), or reclaim before starting the heavyweight tier.

## The 32 pushed repos

Top-level services (14):
- ai-code-agent · batch-inference-engine · distributed-message-queue · feature-serving-system
- gpu-resource-platform · gpu-workload-manager · local-model-serving-api · ml-training-platform
- model-architecture-benchmark · payment-system · personalized-model-agent · proximity-search-service
- recommendation-ads-system · video-streaming-platform

Standalone & umbrellas (3):
- investment-decision-engine · automation-ai-agent · tech-blog-staffeng-impact-axis

Drill subprojects with preserved git history (14):
- drill-p4-distributed-graph-netflix · drill-p20-model-serving-platform
- drill-ad-event-aggregator · drill-chat-system · drill-google-drive · drill-instagram-timeline
- drill-notification-system · drill-payments · drill-s3-object-store · drill-search-auto-complete
- drill-uber-ride · drill-url-shortener · drill-video-streaming · drill-web-crawler

Hub (1):
- project-archiving-logistics

## Reports

- [`../STATUS.md`](../STATUS.md) — per-project dashboard (33 rows × git/CI/origin/size)
- [`../REMOVAL_CANDIDATES.md`](../REMOVAL_CANDIDATES.md) — Section 1 whole-project tiers · Section 2: **9.2GB reclaimable in 32 subdirs**
- [`../logs/bootstrap-run-20260522-154220.log`](../logs/bootstrap-run-20260522-154220.log) — Tier 1 detail
- [`../logs/bootstrap-run-20260522-155142.log`](../logs/bootstrap-run-20260522-155142.log) — Tier 2 detail
- [`../logs/bootstrap.log`](../logs/bootstrap.log) — append-only audit trail

## Daily sync — your activation steps

```bash
cp scripts/com.octarine5.archiving.sync.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/com.octarine5.archiving.sync.plist
launchctl list | grep com.octarine5.archiving.sync   # verify
launchctl start com.octarine5.archiving.sync         # one-shot test (optional)
tail -50 logs/launchd.out.log                        # see what happened
```

Runs daily at **09:15 local time**, committing any uncommitted work as `sync: daily archive YYYY-MM-DD` and pushing.
