
---

## Source control & CI

This repo is part of the [project-archiving-logistics](https://github.com/octarine5/project-archiving-logistics) portfolio sweep. It ships with:

- **One-command local boot**: `make up` (docker-compose: service + Prometheus + Grafana)
- **GitHub Actions CI** ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) — lint + tests + Docker image build to GHCR
- **Nightly load test** ([`.github/workflows/loadtest.yml`](.github/workflows/loadtest.yml)) — locust → artifact CSVs (08:23 UTC daily)
- **Daily local sync** — uncommitted work gets auto-committed and pushed each morning by a launchd job in the archiving hub

## Sample artifacts

Sample request/response pairs (or evaluation outputs, for training projects) live in [`artifacts/samples/`](artifacts/samples/) — small, committed, illustrative.
