#!/usr/bin/env python3
"""Generates REMOVAL_CANDIDATES.md — SUGGESTIONS ONLY. Never deletes anything.

Two sections:

  Section 1 — WHOLE PROJECTS classified by tier (Tier A safe / B review / C keep / X out-of-scope)
  Section 2 — RECLAIMABLE SUBDIRECTORIES inside active projects (venvs, model
              checkpoints, datasets, node_modules) that can be safely removed
              and regenerated.
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
STALE_DAYS = 60
LARGE_MB = 100

RECLAIMABLE = {
    ".venv":              "Python venv — recreate via `pip install -e .` or requirements.txt",
    "venv":               "Python venv",
    "env":                "Python venv",
    "ENV":                "Python venv",
    "contexthub_venv":    "Python venv",
    "node_modules":       "Node deps — recreate via `npm install`",
    ".local":             "Tool-managed local installs (node binaries, JDKs)",
    ".next":              "Next.js build cache",
    ".nuxt":              "Nuxt build cache",
    "dist":               "Build output",
    "build":              "Build output",
    "__pycache__":        "Python bytecode cache",
    ".pytest_cache":      "Pytest cache",
    ".ruff_cache":        "Ruff cache",
    ".mypy_cache":        "Mypy cache",
    ".ipynb_checkpoints": "Jupyter autosaves",
    "checkpoints":        "Model checkpoints — re-trainable",
    "phase_checkpoints":  "Training phase checkpoints",
    "mlruns":             "MLflow runs",
    "wandb":              "Weights & Biases runs",
    "datasets":           "Datasets — re-downloadable",
}


def sh(args, cwd=None, timeout=15):
    try:
        out = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return out.stdout.strip()
    except Exception:
        return ""


def latest_mtime(path):
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


def size_bytes(path):
    try:
        out = subprocess.run(["du", "-sk", str(path)], capture_output=True, text=True, timeout=120)
        return int(out.stdout.split()[0]) * 1024
    except Exception:
        return 0


def last_git_commit(path):
    if not (path / ".git").is_dir():
        return None
    try:
        out = subprocess.run(["git", "log", "-1", "--format=%ct"], cwd=path, capture_output=True, text=True, timeout=10)
        ts = out.stdout.strip()
        return dt.datetime.fromtimestamp(int(ts)) if ts else None
    except Exception:
        return None


def human_size(b):
    for unit, threshold in (("GB", 1 << 30), ("MB", 1 << 20), ("KB", 1 << 10)):
        if b >= threshold:
            return f"{b / threshold:.1f}{unit}"
    return f"{b}B"


def find_reclaimable(root, min_mb=20):
    hits = []
    for entry_root, dirs, _ in os.walk(root):
        if "/.git/" in entry_root or entry_root.endswith("/.git"):
            dirs[:] = []
            continue
        for d in list(dirs):
            if d in RECLAIMABLE:
                full = Path(entry_root) / d
                sb = size_bytes(full)
                if sb >= min_mb * (1 << 20):
                    rel = full.relative_to(root)
                    hits.append({
                        "project": root.name,
                        "path": str(full),
                        "rel": str(rel),
                        "size": human_size(sb),
                        "size_mb": sb / (1 << 20),
                        "kind": d,
                        "reason": RECLAIMABLE[d],
                    })
                dirs.remove(d)
    return hits


def main():
    data = load()
    in_scope = {p["path"] for p in data.get("projects", [])}
    skipped = {s["path"]: s["reason"] for s in data.get("skipped", [])}

    tier_a, tier_b, tier_c, tier_x = [], [], [], []
    for entry in sorted(CODE_ROOT.iterdir()):
        if not entry.is_dir() or entry.name.startswith("."):
            continue
        if entry.name == "project-archiving-logitstics":
            continue
        sb = size_bytes(entry)
        mb = sb / (1 << 20)
        lm = latest_mtime(entry)
        age = (NOW - lm).days
        gc = last_git_commit(entry)
        git_age = (NOW - gc).days if gc else None
        path_str = str(entry)
        info = {
            "path": path_str, "name": entry.name, "size": human_size(sb), "size_mb": mb,
            "last_modified": lm.strftime("%Y-%m-%d"), "age_days": age,
            "last_git": gc.strftime("%Y-%m-%d") if gc else "—",
            "git_age_days": git_age,
            "in_manifest": path_str in in_scope, "skip_reason": skipped.get(path_str),
        }
        if path_str in skipped:
            tier_x.append(info); continue
        if path_str in in_scope and age < STALE_DAYS:
            tier_c.append(info); continue
        if mb > LARGE_MB and age > STALE_DAYS and (git_age is None or git_age > STALE_DAYS):
            tier_a.append(info)
        elif age > STALE_DAYS:
            tier_b.append(info)
        else:
            tier_c.append(info)

    reclaimable = []
    for p in projects():
        path = Path(p["path"])
        if not path.is_dir():
            continue
        reclaimable.extend(find_reclaimable(path, min_mb=20))
    reclaimable.sort(key=lambda x: -x["size_mb"])

    out = []
    out.append(f"# Removal candidates — {NOW.strftime('%Y-%m-%d')}")
    out.append("")
    out.append("> ⚠️ **SUGGESTIONS ONLY** — this script never deletes anything. Review every entry before removing manually.")
    out.append("")
    out.append("## Section 1 · whole projects")
    out.append("")
    out.append("### Disk-use leaderboard (top 15 dirs)")
    out.append("")
    all_entries = tier_a + tier_b + tier_c + tier_x
    leaderboard = sorted(all_entries, key=lambda x: -x["size_mb"])[:15]
    out.append("| Dir | Size | Last touch | Last git | In manifest? |")
    out.append("|---|---|---|---|---|")
    for e in leaderboard:
        out.append(f"| `{e['name']}` | **{e['size']}** | {e['last_modified']} ({e['age_days']}d) | {e['last_git']} | {'✓' if e['in_manifest'] else '—'} |")
    out.append("")

    def render_tier(label, items, note):
        out.append(f"### {label}")
        out.append("")
        out.append(note)
        out.append("")
        if not items:
            out.append("_(none)_"); out.append(""); return
        out.append("| Path | Size | Last modified | Last git | Notes |")
        out.append("|---|---|---|---|---|")
        for e in sorted(items, key=lambda x: -x["size_mb"]):
            notes = []
            if e.get("skip_reason"): notes.append(e["skip_reason"])
            if e["git_age_days"] is not None and e["git_age_days"] > STALE_DAYS:
                notes.append(f"git stale {e['git_age_days']}d")
            if e["in_manifest"]: notes.append("in manifest")
            out.append(f"| `{e['path']}` | {e['size']} | {e['last_modified']} ({e['age_days']}d ago) | {e['last_git']} | {' · '.join(notes) if notes else ''} |")
        out.append("")

    render_tier("🟥 Tier A — likely safe to remove", tier_a,
        f"Big (>{LARGE_MB}MB), stale ({STALE_DAYS}+ days untouched), no recent git, not in manifest.")
    render_tier("🟧 Tier B — review carefully", tier_b,
        "Stale but smaller, or has git history.")
    render_tier("🟩 Tier C — keep (active or in manifest)", tier_c,
        "Recently touched or part of the archived portfolio.")
    render_tier("⬛ Tier X — out of scope, do not touch", tier_x,
        "Notes / personal content explicitly excluded by AUDIT_REPORT.md.")

    out.append("## Section 2 · reclaimable subdirectories inside active projects")
    out.append("")
    total_mb = sum(r['size_mb'] for r in reclaimable)
    out.append(f"Directories ≥20MB inside manifest projects that can be deleted without losing source — they regenerate from `pip install`, `npm install`, or training scripts. **Estimated total reclaimable: " + human_size(int(total_mb * (1 << 20))) + "** across " + str(len(reclaimable)) + " directories.")
    out.append("")
    if not reclaimable:
        out.append("_(none found above 20MB threshold)_")
    else:
        out.append("| Project | Subdir | Size | Kind | How to reclaim |")
        out.append("|---|---|---|---|---|")
        for r in reclaimable:
            out.append(f"| `{r['project']}` | `{r['rel']}` | **{r['size']}** | {r['kind']} | {r['reason']} |")
    out.append("")
    out.append("### Sample reclaim commands")
    out.append("")
    out.append("Review the table above first. To reclaim the largest one-off entries:")
    out.append("")
    out.append("```bash")
    for r in reclaimable[:10]:
        out.append(f"# {r['size']:>8s}  {r['kind']}")
        out.append(f"rm -rf \"{r['path']}\"")
    out.append("```")
    out.append("")
    out.append("---")
    out.append(f"Generated by [`scripts/removal-analysis.py`](scripts/removal-analysis.py) at {NOW.strftime('%Y-%m-%d %H:%M')}.")
    out.append("")

    target = HUB / "REMOVAL_CANDIDATES.md"
    target.write_text("\n".join(out))
    print(f"wrote {target} — A:{len(tier_a)} B:{len(tier_b)} C:{len(tier_c)} X:{len(tier_x)}; reclaimable: {int(total_mb)}MB across {len(reclaimable)} dirs")


if __name__ == "__main__":
    main()
