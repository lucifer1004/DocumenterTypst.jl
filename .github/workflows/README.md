# CI/CD Workflows

## Overview

This project uses GitHub Actions for automated testing, documentation, and maintenance.

## Workflows

### CI.yml - Main Pipeline

**Runs on**: Every push to main, PRs, tags

**What it does**:

- **Path filtering**: Skips unnecessary tests for docs-only changes
- **Code quality**: Format checks (Runic, markdownlint), spell check (typos)
- **Tests**: Unit, integration, and visual snapshot tests across Julia versions and platforms
- **Documentation**: Builds HTML docs and deploys to GitHub Pages
- **Releases**: Creates GitHub releases on new tags

**Key feature**: Smart path detection - README typo fixes run in ~20s instead of ~20min.

### Changelog.yml - Changelog Enforcement

**Runs on**: Pull requests

**What it does**: Ensures PRs update `CHANGELOG.md` or have "Skip Changelog" label.

### CompatCheck.yml - Upstream Compatibility Monitor

**Runs on**: Weekly (Monday), manual dispatch

**What it does**: Tests against `Documenter.jl#main` to catch breaking changes early. Auto-creates issues on failure.

### CompatHelper.yml - Dependency Version Manager

**Runs on**: Daily, manual dispatch

**What it does**: Checks for new releases of dependencies and creates PRs to update `[compat]` bounds in `Project.toml`.

### TagBot.yml - Automatic Releases

**Runs on**: Issue comments, manual dispatch

**What it does**: Creates Git tags after package registration in Julia General registry.

## Local Development

### Run Tests

```bash
just test                  # All tests
just test-snapshot-update  # Update snapshots
```

### Format Code

```bash
just format  # Runic (Julia) + markdownlint-cli2 (Markdown)
```

### Build Documentation

```bash
just docs        # HTML docs
just docs-typst  # PDF via Typst
```

### Check Spelling

```bash
typos                # Check
typos --write-changes  # Fix
```

## Required Secrets

- **DOCUMENTER_KEY**: SSH key for docs deployment (see [Documenter docs](https://documenter.juliadocs.org/stable/man/hosting/))
- **CODECOV_TOKEN**: For coverage reports (optional)
- **GITHUB_TOKEN**: Auto-provided by GitHub

## Debugging CI Failures

### Format Errors

```bash
just format
git add -A && git commit -m "fix: apply formatting"
```

### Typos

```bash
typos
# If false positive, add to .typos.toml
```

### Snapshot Mismatches

Visual snapshots use `--ignore-system-fonts` for cross-platform consistency. If legitimate change:

```bash
UPDATE_SNAPSHOTS=1 julia --project=. test/run_snapshot_tests.jl
git add test/snapshots/visual/*.hash
```

## Design Philosophy

**Fast feedback**: Quality checks run first and fast. Path filtering skips irrelevant tests.

**Defensive layers**:

- CompatHelper tracks stable releases
- CompatCheck warns about upcoming breaking changes

**Zero waste**: Concurrency control cancels outdated PR runs, but never cancels main branch builds.

## Maintenance

Check for action updates periodically:

- `actions/checkout`
- `julia-actions/setup-julia`
- `codecov/codecov-action`
- `fredrikekre/runic-action`

Keep minimum Julia version in sync with `Project.toml` compat bounds.
