# Removal candidates — 2026-05-22

> ⚠️  **SUGGESTIONS ONLY.** This script never deletes anything. Review each candidate before removing manually.

## How tiers are assigned

- **Tier A — likely safe to remove**: size >100MB AND not modified in 60+ days AND no recent git commits AND not in `MANIFEST.yaml`.
- **Tier B — review carefully**: not modified in 60+ days but small or has git history. May still contain unique work.
- **Tier C — keep**: actively touched recently or in manifest.
- **Tier X — do not touch**: explicitly out-of-audit-scope content (notes, audio, diagrams).

## Disk-use leaderboard (top dirs)

| Dir | Size | Last touch | Last git | In manifest? |
|---|---|---|---|---|
| `automation_ai_agent` | **4.6GB** | 2026-05-22 (0d) | 2026-04-07 | ✓ |
| `ml-training-platform` | **2.4GB** | 2026-05-22 (0d) | 2026-03-30 | ✓ |
| `leverage_work_prototypes_drill` | **1.6GB** | 2026-05-21 (1d) | — | ✓ |
| `tech-blog-staffeng-impact-axis` | **419.4MB** | 2026-05-22 (0d) | — | ✓ |
| `recorded_audio_notes` | **390.4MB** | 2026-03-30 (52d) | — | — |
| `crafting_system_design_drill` | **216.9MB** | 2026-05-13 (9d) | — | — |
| `enterprise_research_portofolio` | **213.7MB** | 2026-05-22 (0d) | — | — |
| `gpu-resource-platform` | **213.4MB** | 2026-05-21 (1d) | 2026-03-30 | ✓ |
| `investment_decision_engine` | **186.7MB** | 2026-05-21 (1d) | — | ✓ |
| `local-model-serving-api` | **95.2MB** | 2026-05-22 (0d) | 2026-03-30 | ✓ |
| `video-streaming-platform` | **94.3MB** | 2026-05-21 (1d) | 2026-03-30 | ✓ |
| `gpu-workload-manager` | **67.4MB** | 2026-05-21 (1d) | 2026-03-30 | ✓ |
| `distributed-message-queue` | **62.9MB** | 2026-05-21 (1d) | 2026-03-30 | ✓ |
| `proximity-search-service` | **62.8MB** | 2026-05-21 (1d) | 2026-03-30 | ✓ |
| `ai-code-agent` | **43.4MB** | 2026-05-21 (1d) | 2026-03-30 | ✓ |

## 🟥 Tier A — likely safe to remove

Big, stale, no recent git, and not in the manifest. **Before deleting, double-check that anything you want lives in the backed-up GitHub repos or elsewhere.**

_(none)_

## 🟧 Tier B — review carefully

Stale but smaller — may hold unique work (notes, drafts, single-file experiments). Spot-check contents before removing.

_(none)_

## 🟩 Tier C — keep (active or in manifest)

Recently touched or part of the archived portfolio. Do not delete.

| Path | Size | Last modified | Last git | Notes |
|---|---|---|---|---|
| `/Users/diwang/Code/automation_ai_agent` | 4.6GB | 2026-05-22 (0d ago) | 2026-04-07 | in manifest |
| `/Users/diwang/Code/ml-training-platform` | 2.4GB | 2026-05-22 (0d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/leverage_work_prototypes_drill` | 1.6GB | 2026-05-21 (1d ago) | — | in manifest |
| `/Users/diwang/Code/tech-blog-staffeng-impact-axis` | 419.4MB | 2026-05-22 (0d ago) | — | in manifest |
| `/Users/diwang/Code/crafting_system_design_drill` | 216.9MB | 2026-05-13 (9d ago) | — |  |
| `/Users/diwang/Code/gpu-resource-platform` | 213.4MB | 2026-05-21 (1d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/investment_decision_engine` | 186.7MB | 2026-05-21 (1d ago) | — | in manifest |
| `/Users/diwang/Code/local-model-serving-api` | 95.2MB | 2026-05-22 (0d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/video-streaming-platform` | 94.3MB | 2026-05-21 (1d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/gpu-workload-manager` | 67.4MB | 2026-05-21 (1d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/distributed-message-queue` | 62.9MB | 2026-05-21 (1d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/proximity-search-service` | 62.8MB | 2026-05-21 (1d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/ai-code-agent` | 43.4MB | 2026-05-21 (1d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/personalized-model-agent` | 1.5MB | 2026-05-21 (1d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/batch-inference-engine` | 1.4MB | 2026-05-22 (0d ago) | 2026-05-22 | in manifest |
| `/Users/diwang/Code/payment-system` | 732.0KB | 2026-05-21 (1d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/recommendation-ads-system` | 724.0KB | 2026-05-21 (1d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/feature-serving-system` | 608.0KB | 2026-05-21 (1d ago) | 2026-03-30 | in manifest |
| `/Users/diwang/Code/model-architecture-benchmark` | 532.0KB | 2026-05-21 (1d ago) | 2026-03-30 | in manifest |

## ⬛ Tier X — out of scope, do not touch

Notes / personal content / diagrams that the audit explicitly excluded. Not service code.

| Path | Size | Last modified | Last git | Notes |
|---|---|---|---|---|
| `/Users/diwang/Code/recorded_audio_notes` | 390.4MB | 2026-03-30 (52d ago) | — | Audio dumps. |
| `/Users/diwang/Code/enterprise_research_portofolio` | 213.7MB | 2026-05-22 (0d ago) | — | Mixed Java/Scala/C++ research; out of audit shape. Not in user's selected scope. |
| `/Users/diwang/Code/behavior_org_owner_decision` | 31.3MB | 2026-04-07 (45d ago) | — | Audio + book notes. |
| `/Users/diwang/Code/vision_directions_passion` | 16.3MB | 2026-04-19 (32d ago) | 2026-04-07 | Personal vision pages. |
| `/Users/diwang/Code/career_cto_roadmap` | 15.4MB | 2026-04-09 (43d ago) | — | Personal planning, not a service. |
| `/Users/diwang/Code/_templates` | 80.0KB | 2026-05-21 (1d ago) | — | Shared scaffolding; lives in this hub instead. |
| `/Users/diwang/Code/_diagrams` | 32.0KB | 2026-03-30 (52d ago) | — | Diagrams + PDFs, no service. |

---

Generated by [`scripts/removal-analysis.py`](scripts/removal-analysis.py) at 2026-05-22 15:39.
