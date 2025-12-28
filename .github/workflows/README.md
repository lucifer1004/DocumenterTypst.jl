# CI Workflow Documentation

This directory contains GitHub Actions workflows for continuous integration and documentation deployment.

## Workflows

### 1. CI.yml - Main CI Pipeline

**Triggers**: Push to main, tags, pull requests, manual

**Jobs**:

- **test**: Multi-platform testing matrix
  - Julia versions: 1.10 (minimum), 1 (latest)
  - OS: Ubuntu, macOS, Windows
  - Arch: x64
  - Features: Code coverage (Ubuntu only), artifacts

- **docs**: Build HTML documentation
  - Uses `julia-docdeploy` for automatic deployment
  - Uploads artifacts for inspection

- **format-check**: Ensures code formatting (JuliaFormatter)
  - Uses BlueStyle
  - Fails if code not properly formatted

- **quality-assurance**: Runs Aqua.jl checks (PR only)
  - Dependency compat check
  - Stale dependencies check
  - Undefined exports check

- **release**: Creates GitHub releases (tags only)
  - Generates release notes
  - Marks pre-releases (rc, beta)

- **notify-failure**: Creates issue on CI failure (main only)

**Caching Strategy**:

- Julia packages: Per OS/arch/version
- Registries: Shared across jobs
- Artifacts: Shared across jobs

**Secrets Required**:

- `CODECOV_TOKEN`: For Codecov upload (optional)

### 2. Changelog.yml - Changelog Enforcement

**Purpose**: Enforce changelog updates on all pull requests.

**Triggers**:

- Pull request events: `opened`, `synchronize`, `reopened`, `ready_for_review`, `labeled`, `unlabeled`

**Requirements**:

- All user-visible changes must update `CHANGELOG.md` under "Unreleased" section
- Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
- Can be bypassed by adding "Skip Changelog" or "dependencies" labels

**Categories**:

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

**Example Entry**:

```markdown
## Unreleased

### Added

- Support for custom fonts. ([#42])

### Fixed

- Math rendering in tables. ([#43])
```

### 3. Documenter.yml - Documentation Pipeline

**Triggers**: Push to main, tags, pull requests

**Jobs**:

- **build**: Build HTML documentation
  - Full Documenter pipeline
  - Debug logging enabled
  - Uploads artifacts

- **preview-comment**: Add PR comment with preview info
  - Automatically updates existing comments
  - Provides workflow run link

**Permissions**: `contents: write`, `pages: write`, `pull-requests: write`

**Secrets Required**:

- `DOCUMENTER_KEY`: For docs deployment

**Documentation Structure**:

```
docs/
├── make.jl                      # Build script with changelog generation
├── changelog.jl                 # Standalone changelog generator
├── Project.toml                 # Doc dependencies
└── src/
    ├── index.md                 # Homepage
    ├── release-notes.md         # Auto-generated from CHANGELOG.md
    ├── contributing.md          # Contribution guidelines
    ├── manual/                  # User manual
    ├── examples/                # Usage examples
    └── api/                     # API reference
```

**Changelog Generation**:
The workflow automatically converts `CHANGELOG.md` to `docs/src/release-notes.md` using Documenter's Changelog extension:

```julia
Changelog = Base.get_extension(Documenter, :DocumenterChangelogExt)
Changelog.generate(
    Changelog.CommonMark(),
    joinpath(@__DIR__, "..", "CHANGELOG.md"),
    joinpath(@__DIR__, "src", "release-notes.md");
    repo = "lucifer1004/DocumenterTypst.jl",
)
```

**Manual Build**:

```bash
make docs
# or
julia --project=docs docs/make.jl
```

### 4. TagBot.yml - Automatic Release Tagging

**Triggers**: Issue comments (JuliaTagBot), manual dispatch

**Purpose**: Automatically create Git tags when registered in General

**Permissions**: All read, `contents: write`

**Secrets Required**:

- `GITHUB_TOKEN`: Automatic
- `DOCUMENTER_KEY`: For SSH push

### 5. CompatCheck.yml - Compatibility Monitoring

**Triggers**: Weekly (Monday 00:00 UTC), manual

**Purpose**: Test against Documenter.jl development version

**Behavior**:

- Tests with `Documenter#main`
- Creates issue on failure
- Updates/closes existing compat issues
- Does not fail CI (informational)

**Features**:

- Early warning for breaking changes
- Automatic issue management
- Weekly monitoring

## Local Development Workflow

### Initial Setup

```bash
git clone https://github.com/lucifer1004/DocumenterTypst.jl.git
cd DocumenterTypst.jl
make dev
```

### Development Cycle

```bash
# 1. Make code changes
vim src/TypstWriter.jl

# 2. Format code
make format

# 3. Run tests
make test

# 4. Update CHANGELOG.md (if user-visible change)
vim CHANGELOG.md

# 5. Build docs locally
make docs

# 6. Generate changelog for docs
make changelog

# 7. Commit and push
git add -A
git commit -m "Add feature X"
git push origin feature-branch
```

### Quick Commands

| Command                  | Description                   |
| ------------------------ | ----------------------------- |
| `make dev`               | Install package in dev mode   |
| `make test`              | Run test suite                |
| `make format`            | Format all Julia code         |
| `make docs`              | Build HTML documentation      |
| `make docs-typst`        | Build Typst/PDF documentation |
| `make docs-typst-native` | Build PDF with system Typst   |
| `make docs-typst-source` | Generate .typ source only     |
| `make changelog`         | Generate release notes        |
| `make clean`             | Clean build artifacts         |

### Manual Documentation Builds

```bash
# HTML (default)
julia --project=docs docs/make.jl

# HTML with local URLs
julia --project=docs docs/make.jl local

# Typst/PDF with Typst_jll (default)
julia --project=docs docs/make.jl typst

# Typst/PDF with native compiler
julia --project=docs docs/make.jl typst native

# Typst source only (no compilation)
julia --project=docs docs/make.jl typst none

# Enable link checking
julia --project=docs docs/make.jl linkcheck

# Run doctests only
julia --project=docs docs/make.jl doctest=only

# Warnings as warnings (not errors)
julia --project=docs docs/make.jl strict=false
```

## Setup Instructions

### 1. Required Secrets

Add these to repository settings → Secrets and variables → Actions:

```bash
# Required for docs deployment
DOCUMENTER_KEY=<SSH private key>

# Optional for code coverage
CODECOV_TOKEN=<codecov token>
```

#### Generate DOCUMENTER_KEY:

```bash
# On your machine
julia -e '
  using DocumenterTools
  using DocumenterTools: Travis
  Travis.genkeys(user="lucifer1004", repo="DocumenterTypst.jl")
'
```

This generates:

- Public key → Add as deploy key in GitHub (Settings → Deploy keys)
- Private key → Add as `DOCUMENTER_KEY` secret

### 2. Enable GitHub Pages

Settings → Pages:

- Source: Deploy from a branch
- Branch: `gh-pages` / `root`

### 3. Branch Protection (Optional but Recommended)

Settings → Branches → Add rule for `main`:

- ✅ Require status checks to pass
- Select: `test`, `docs`, `format-check`
- ✅ Require branches to be up to date

### 4. Code Coverage (Optional)

**Codecov**:

1. Sign up at https://codecov.io
2. Add repository
3. Copy token to `CODECOV_TOKEN` secret

**Coveralls**:

1. Sign up at https://coveralls.io
2. Add repository (token automatic via `GITHUB_TOKEN`)

## Local Testing

### Test CI Locally (act)

Install [act](https://github.com/nektos/act):

```bash
# Test full CI
act -j test

# Test docs build
act -j docs

# Test specific job
act -j format-check
```

### Format Code

```bash
julia -e 'using JuliaFormatter; format(".")'
```

### Build Docs Locally

```bash
julia --project=docs -e '
  using Pkg
  Pkg.develop(PackageSpec(path=pwd()))
  Pkg.instantiate()
  include("docs/make.jl")
'
```

## Troubleshooting

### CI Fails on Specific Platform

Check platform-specific issues:

```yaml
matrix:
  exclude:
    - os: windows-latest
      version: "1.10" # Skip problematic combos
```

### Docs Deployment Fails

1. Check `DOCUMENTER_KEY` is valid
2. Verify deploy key is added to repo
3. Check permissions on gh-pages branch
4. Enable GitHub Pages in settings

### Compat Check False Positives

If Documenter#main changes are expected:

1. Update DocumenterTypst code
2. Or add `continue-on-error: true` temporarily
3. Close auto-created issue with explanation

### Cache Issues

Clear caches manually:

1. Go to Actions → Caches
2. Delete specific cache
3. Re-run workflow

## Performance Optimization

Current optimizations:

- ✅ Concurrent jobs
- ✅ Aggressive caching
- ✅ Cancel redundant runs
- ✅ Platform-specific matrix
- ✅ Conditional jobs (format-check on PR only)

Typical timing:

- test: ~5-10 min per platform
- docs: ~3-5 min
- format-check: ~1 min
- Total (parallel): ~10-15 min

## Maintenance

### Monthly Tasks

- [ ] Review cache hit rates
- [ ] Check for workflow updates (actions/\*)
- [ ] Review failed compat checks

### Quarterly Tasks

- [ ] Audit permissions
- [ ] Update Julia versions in matrix
- [ ] Review and update dependencies

### On Documenter.jl Releases

- [ ] Update compat in Project.toml
- [ ] Test with new version
- [ ] Update docs if API changed

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [julia-actions](https://github.com/julia-actions)
- [Documenter.jl CI Guide](https://documenter.juliadocs.org/stable/man/hosting/)
