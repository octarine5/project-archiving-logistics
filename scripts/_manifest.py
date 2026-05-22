"""Shared manifest loader. Returns the list of project dicts from MANIFEST.yaml."""
from __future__ import annotations
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required. Install with: pip3 install pyyaml")

HUB = Path(__file__).resolve().parents[1]
MANIFEST = HUB / "MANIFEST.yaml"


def load() -> dict:
    with MANIFEST.open() as fh:
        return yaml.safe_load(fh)


def projects(include_skipped: bool = False) -> list[dict]:
    data = load()
    return [p for p in data.get("projects", []) if include_skipped or not p.get("skip")]


if __name__ == "__main__":
    for p in projects():
        print(f"{p['repo']:45s} {p['stack']:10s} {p['kind']:10s} {p['path']}")
