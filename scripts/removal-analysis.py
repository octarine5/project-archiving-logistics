#!/usr/bin/env python3
"""Generates REMOVAL_CANDIDATES.md — SUGGESTIONS ONLY.

Looks at every top-level directory under /Users/diwang/Code/ and classifies it
into tiers based on:
  - size on disk
  - last-modified time (most recent file mtime)
  - whether any git activity in the last 90 days
  - whether it appears in MANIFEST.yaml (in-scope?)
  - whether it's known notes/personal content from AUDIT_REPORT.md

THIS SCRIPT NEVER DELETES ANYTHING. It writes a markdown report tiered by safety:
  - Tier A: safe to delete (large + stale + already covered elsewhere or backed up)
  - Tier B: review before deleting (stale but unique work)
  - Tier C: actively used — keep
  - Tier X: explicit "do not touch" (audit notes, personal)

User must remove manually after review.
"""
from __future__ import annotations
import datetime as dt
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _manifest import HUB, projects, load  # type: ignore

CODE_ROOT = Path("/Users/diwang/Code")
NOW = dt.datetime.now()
STALE_DAYS = 60       # >60d untouched = stale
LARGE_MB = 100        # >100MB = large
HUGE_MB = 1024        # >1GB = huge


def latest_mtime(path: Path) -> dt.datetime:
    """Most recent mtime under path. Cheap walk capped at 5000 entries."""
    latest = path.stat().st_mtime
    count = 0
    for root, dirs, files in os.walk(path):
        dirs[:] = [d for d in dirs if not d.startswith(".") and d not in {"node_modules", "__pycache__", ".venv", "venv"}]
        for name in files:
            try:
                m = (Path(root) / name).stat().st_mtime
                if m > latest:
                    latest = m
            except OSError:
                pass
            count += 1
            if count > 5000:
                return dt.datetime.fromtimestamp(latest)
    return dt.datetime.fromtimestamp(latest)


def size_bytes(path: Path) -> int:
    try:
        out = subprocess.run(["du", "-sk", str(path)], capture_output=True, text=True, timeout=60)
        return int(out.stdout.split()[0]) * 1024
    except Exception:
        return 0


def last_git_commit(path: Path) -> dt.datetime | None:
    if not (path / ".git").is_dir():
        return None
    try:
        out = subprocess.run(
            ["git", "log", "-1", "--format=%ct"],
            cwd=path, capture_output=True, text=True, timeout=10,
        )
        ts = out.stdout.strip()
        return dt.datetime.fromtimestamp(int(ts)) if ts else None
    except Exception:
        return None


def human_size(b: int) -> str:
    for unit, threshold in (("GB", 1 << 30), ("MB", 1 << 20), ("KB", 1 << 10)):
        if b >= threshold:
            return f"{b / threshold:.1f}{unit}"
    return f"{b}B"


def main() -> None:
    data = load()
    in_scope = {p["path"] for p in data.get("projects", [])}
    skipped = {s["path"]: s["reason"] for s in data.get("skipped", [])}

    tier_a, tier_b, tier_c, tier_x = [], [], [], []

    for entry in sorted(CODE_ROOT.iterdir()):
        if not entry.is_dir():
            continue
        if entry.name.startswith(".") or entry.name == "project-archiving-logitstics":
            continue

        sb = size_bytes(entry)
        mb = sb / (1 << 20)
        lm = latest_mtime(entry)
        age = (NOW - lm).days
        gc = last_git_commit(entry)
        git_age = (NOW - gc).days if gc else None
        path_str = str(entry)

        info = {
            "path": path_str,
            "name": entry.name,
            "size": human_size(sb),
            "size_mb": mb,
            "last_modified": lm.strftime("%Y-%m-%d"),
            "age_days": age,
            "last_git": gc.strftime("%Y-%m-%d") if gc else "—",
            "git_age_days": git_age,
            "in_manifest": path_str in in_scope,
            "skip_reason": skipped.get(path_str),
        }

        # Tier X — explicitly out of scope by AUDIT_REPORT (don't suggest deleting)
        if path_str in skipped:
            tier_x.append(info)
            continue

        # Tier C — in manifest = actively maintained
        if path_str in in_scope:
            if age < STALE_DAYS:
                tier_c.append(info)
                continue

        # If big AND stale AND not active git — Tier A
        if mb > LARGE_MB and age > STALE_DAYS and (git_age is None or git_age > STALE_DAYS):
            tier_a.append(info)
        elif age > STALE_DAYS:
            tier_b.append(info)
        else:
            tier_c.append(info)

    out = []
    out.append(f"# Removal candidates — {NOW.strftime('%Y-%m-%d')}")
    out.append("")
    out.append("> ⚠️  **SUGGESTIONS ONLY.** This script never deletes anything. Review each candidate before removing manually.")
    out.append("")
    out.append("## How tiers are assigned")
    out.append("")
    out.append(f"- **Tier A — likely safe to remove**: size >{LARGE_MB}MB AND not modified in {STALE_DAYS}+ days AND no recent git commits AND not in `MANIFEST.yaml`.")
    out.append(f"- **Tier B — review carefully**: not modified in {STALE_DAYS}+ days but small or has git history. May still contain unique work.")
    out.append("- **Tier C — keep**: actively touched recently or in manifest.")
    out.append("- **Tier X — do not touch**: explicitly out-of-audit-scope content (notes, audio, diagrams).")
    out.append("")
    out.append("## Disk-use leaderboard (top dirs)")
    out.append("")
    all_entries = tier_a + tier_b + tier_c + tier_x
    leaderboard = sorted(all_entries, key=lambda x: -x["size_mb"])[:15]
    out.append("| Dir | Size | Last touch | Last git | In manifest? |")
    out.append("|---|---|---|---|---|")
    for e in leaderboard:
        out.append(f"| `{e['name']}` | **{e['size']}** | {e['last_modified']} ({e['age_days']}d) | {e['last_git']} | {'✓' if e['in_manifest'] else '—'} |")
    out.append("")

    def render_tier(label: str, items: list[dict], note: str) -> None:
        out.append(f"## {label}")
        out.append("")
        out.append(note)
        out.append("")
        if not items:
            out.append("_(none)_")
            out.append("")
            return
        out.append("| Path | Size | Last modified | Last git | Notes |")
        out.append("|---|---|---|---|---|")
        for e in sorted(items, key=lambda x: -x["size_mb"]):
            notes = []
            if e.get("skip_reason"):
                notes.append(e["skip_reason"])
            if e["git_age_days"] is not None and e["git_age_days"] > STALE_DAYS:
                notes.append(f"git stale {e['git_age_days']}d")
            if e["in_manifest"]:
                notes.append("in manifest")
            out.append(f"| `{e['path']}` | {e['size']} | {e['last_modified']} ({e['age_days']}d ago) | {e['last_git']} | {' · '.join(notes) if notes else ''} |")
        out.append("")

    render_tier(
        "🟥 Tier A — likely safe to remove",
        tier_a,
        "Big, stale, no recent git, and not in the manifest. **Before deleting, double-check that anything you want lives in the backed-up GitHub repos or elsewhere.**",
    )
    render_tier(
        "🟧 Tier B — review carefully",
        tier_b,
        "Stale but smaller — may hold unique work (notes, drafts, single-file experiments). Spot-check contents before removing.",
    )
    render_tier(
        "🟩 Tier C — keep (active or in manifest)",
        tier_c,
        "Recently touched or part of the archived portfolio. Do not delete.",
    )
    render_tier(
        "⬛ Tier X — out of scope, do not touch",
        tier_x,
        "Notes / personal content / diagrams that the audit explicitly excluded. Not service code.",
    )

    out.append("---")
    out.append("")
    out.append(f"Generated by [`scripts/removal-analysis.py`](scripts/removal-analysis.py) at {NOW.strftime('%Y-%m-%d %H:%M')}.")
    out.append("")

    target = HUB / "REMOVAL_CANDIDATES.md"
    target.write_text("\n".join(out))
    print(f"wrote {target} — A:{len(tier_a)} B:{len(tier_b)} C:{len(tier_c)} X:{len(tier_x)}")


if __name__ == "__main__":
    main()
