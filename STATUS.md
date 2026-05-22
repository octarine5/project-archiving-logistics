# Portfolio status — 2026-05-22 15:39

**Manifest:** [`MANIFEST.yaml`](MANIFEST.yaml) — 33 projects

## Headline

- 29/33 have local git
- 0/33 have a GitHub remote (origin set)
- 0/33 have CI workflow installed
- 29/33 have uncommitted local work

## Per-project state

| Repo | Kind | Stack | Wave | SLO | Exists | Git | Origin | Branch | Dirty | Last commit | CI | Load | Art | Size |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `ai-code-agent` | service | python | 1 | True | ✓ | ✓ | ✗ | master | 7 | 2026-03-30 · Add tests for core modules | ✗ | — | ✗ | 43M |
| `batch-inference-engine` | service | python | 1 | True | ✓ | ✓ | ✗ | master | 12 | 2026-05-22 · Add cross-backend benchmark harness | ✗ | — | ✗ | 1.4M |
| `distributed-message-queue` | service | python | 1 | True | ✓ | ✓ | ✗ | master | 9 | 2026-03-30 · Add API routes, broker coordination, and tests | ✗ | — | ✗ | 63M |
| `feature-serving-system` | service | python | 1 | near | ✓ | ✓ | ✗ | master | 7 | 2026-03-30 · Add API routes, fleet management, and tests | ✗ | — | ✗ | 608K |
| `gpu-resource-platform` | service | python | 1 | True | ✓ | ✓ | ✗ | master | 7 | 2026-03-30 · Add API routes, observability, and tests | ✗ | — | ✗ | 213M |
| `gpu-workload-manager` | service | python | 1 | True | ✓ | ✓ | ✗ | master | 7 | 2026-03-30 · Add API routes, cross-stage resource sharing, a | ✗ | — | ✗ | 67M |
| `local-model-serving-api` | service | python | 1 | True | ✓ | ✓ | ✗ | master | 14 | 2026-03-30 · Add alerting, tests, and Makefile | ✗ | — | ✗ | 95M |
| `ml-training-platform` | service | python | 1 | False | ✓ | ✓ | ✗ | master | 32 | 2026-03-30 · Add fine-tuning, CLI, and tests | ✗ | — | ✗ | 2.4G |
| `model-architecture-benchmark` | cli | python | 1 | True | ✓ | ✓ | ✗ | master | 8 | 2026-03-30 · Add CLI, presets, and tests | ✗ | — | ✗ | 532K |
| `payment-system` | service | python | 1 | True | ✓ | ✓ | ✗ | master | 7 | 2026-03-30 · Add API routes, fraud detection, and tests | ✗ | — | ✗ | 732K |
| `personalized-model-agent` | service | python | 1 | True | ✓ | ✓ | ✗ | master | 9 | 2026-03-30 · Add use case templates, tests, and CLI | ✗ | — | ✗ | 1.5M |
| `proximity-search-service` | service | python | 1 | True | ✓ | ✓ | ✗ | master | 9 | 2026-03-30 · Add API routes, filters, and tests | ✗ | — | ✗ | 63M |
| `recommendation-ads-system` | service | python | 1 | True | ✓ | ✓ | ✗ | master | 6 | 2026-03-30 · Add API routes, metrics, and tests | ✗ | — | ✗ | 724K |
| `video-streaming-platform` | service | python | 1 | True | ✓ | ✓ | ✗ | master | 8 | 2026-03-30 · Add API routes, notifications, and tests | ✗ | — | ✗ | 94M |
| `investment-decision-engine` | service | python | 2 | True | ✓ | ✗ | ✗ | — | — | — | ✗ | — | ✗ | 187M |
| `automation-ai-agent` | umbrella | polyglot | 2 | mixed | ✓ | ✓ | ✗ | main | 276 | 2026-04-07 · Add daily OneNote summary cron script + system  | ✗ | — | ✗ | 4.6G |
| `leverage-work-prototypes-drill` | umbrella | python | 2 | mixed | ✓ | ✗ | ✗ | — | — | — | ✗ | — | ✗ | 1.6G |
| `drill-p4-distributed-graph-netflix` | service | python | 3 | True | ✓ | ✓ | ✗ | main | 6 | 2025-12-26 · initial distributed graph for netflix setup | ✗ | — | ✗ | 252K |
| `drill-p20-model-serving-platform` | service | python | 2 | True | ✓ | ✓ | ✗ | master | 15 | 2026-03-28 · docs: add TRACES.md (bugs, fixes, design decisi | ✗ | — | ✗ | 5.4M |
| `drill-ad-event-aggregator` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 6 | 2026-03-29 · feat: add main app, tests (29/29 passing), fix  | ✗ | — | ✗ | 724K |
| `drill-chat-system` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 6 | 2026-03-29 · Add TRACES.md - 15 problems, bugs, and design f | ✗ | — | ✗ | 736K |
| `drill-google-drive` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 8 | 2026-03-30 · add TRACES.md for problem/bug tracking and .git | ✗ | — | ✗ | 952K |
| `drill-instagram-timeline` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 9 | 2026-03-28 · Phase 7: Traces document, monitoring, and final | ✗ | — | ✗ | 616K |
| `drill-notification-system` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 5 | 2026-03-29 · Phase 7: Tests (27 passing), trace documentatio | ✗ | — | ✗ | 38M |
| `drill-payments` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 5 | 2026-03-28 · feat: add server entry point and integration te | ✗ | — | ✗ | 620K |
| `drill-s3-object-store` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 9 | 2026-03-28 · Add TRACES.md with debug traces, bug fixes, and | ✗ | — | ✗ | 47M |
| `drill-search-auto-complete` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 6 | 2026-03-30 · Add TRACES.md with design decisions, problems,  | ✗ | — | ✗ | 1.2M |
| `drill-uber-ride` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 6 | 2026-03-28 · Phase 7: TRACES.md — comprehensive design trace | ✗ | — | ✗ | 1.0M |
| `drill-url-shortener` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 18 | 2026-03-27 · feat: Phase 1 - core redirect loop (POST /short | ✗ | — | ✗ | 432K |
| `drill-video-streaming` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 4 | 2026-03-29 · Revise V2 evaluation — scoped to upload and str | ✗ | — | ✗ | 65M |
| `drill-web-crawler` | service | python | none | n/a | ✓ | ✓ | ✗ | master | 8 | 2026-03-27 · Add implementation trace, problems, and bug fix | ✗ | — | ✗ | 664K |
| `tech-blog-staffeng-impact-axis` | notes | unknown | none | n/a | ✓ | ✗ | ✗ | — | — | — | ✗ | — | ✗ | 419M |
| `project-archiving-logistics` | hub | shell | none | n/a | ✓ | ✗ | ✗ | — | — | — | ✗ | — | ✗ | 68K |

## Legend

- **Wave** — audit wave (1/2/3) from `AUDIT_REPORT.md` + `COMPLETION_REPORT.md`
- **SLO** — `yes` / `no` / `near` / `mixed` from measured load tests in `COMPLETION_REPORT.md`
- **Dirty** — count of uncommitted files
- **CI / Load / Art** — `.github/workflows/ci.yml`, `loadtest.yml`, `artifacts/samples/` present?

Generated by [`scripts/status.py`](scripts/status.py) at 2026-05-22 15:39.
