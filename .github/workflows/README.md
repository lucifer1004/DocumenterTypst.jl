# DocumenterTypst.jl CI/CD Workflows

This directory contains comprehensive CI/CD configuration for DocumenterTypst.jl.

## Workflows

### 1. CI.yml - Main CI Pipeline

**Triggers**: Push to main/release branches, tags, PRs, manual dispatch

**Jobs**:

#### Code Quality Checks

1. **changelog** - Enforces CHANGELOG.md updates on PRs
   - Can be skipped with labels: `Skip Changelog`, `dependencies`
2. **runic** - Julia code formatting with Runic.jl
   - Julia 1.11 + Runic 1.2
3. **prettier** - Format checking for JS/JSON/YAML/MD
   - Uses `.prettierrc` config
4. **typos** - Spell checking
   - Uses `.typos.toml` config

#### Testing

5. **test** - Multi-platform test matrix
   - Julia: 1.10 (min), 1 (stable), nightly
   - OS: Ubuntu, macOS, Windows
   - Arch: x64
   - Coverage: Codecov + Coveralls (parallel submission)
6. **typst-backend** - Typst-specific integration tests
   - Platforms: `typst` (Typst_jll), `native`, `none`
   - OS: Ubuntu, Windows
   - Tests all compilation backends
   - Uploads `.typ` and `.pdf` artifacts

#### Documentation

7. **docs** - Build and deploy documentation
   - Uses `julia-docdeploy` action
   - Deploys to GitHub Pages
   - PR previews enabled
8. **linkcheck** - Verify external links in documentation
   - Runs `makedocs` with `linkcheck` option

#### Finalization

9. **close-coveralls** - Finalize parallel coverage submission
10. **release** - Create GitHub releases (tags only)
    - Generates release notes
    - Marks pre-releases (rc/beta)

### 2. Changelog.yml - Changelog Enforcement

**Triggers**: PR events (opened, synchronized, labeled)

**Purpose**: Ensure all PRs update CHANGELOG.md

### 3. Documenter.yml - Documentation Deployment

**Triggers**: Push to main, tags, PRs

**Purpose**: Build and deploy documentation to GitHub Pages

### 4. TagBot.yml - Automatic Release Tagging

**Triggers**: Issue comments, manual dispatch

**Purpose**: Create Git tags when registered in Julia General

### 5. CompatCheck.yml - Compatibility Monitoring

**Triggers**: Weekly (Monday), manual

**Purpose**: Test against Documenter.jl development version

## Concurrency Control

Following Documenter.jl pattern:

```yaml
group: ${{ github.workflow }}-${{ github.ref }}-${{ github.ref != 'refs/heads/main' || github.run_number }}
cancel-in-progress: ${{ startsWith(github.ref, 'refs/pull/') }}
```

- PRs: Only 1 concurrent job, cancels on new push
- Main branch: All jobs run (no cancellation)

## Required Secrets

1. **CODECOV_TOKEN** - For Codecov uploads (optional but recommended)
2. **DOCUMENTER_KEY** - SSH key for documentation deployment
3. **GITHUB_TOKEN** - Automatically provided

## Setup Instructions

### Generate DOCUMENTER_KEY

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "documenter" -f documenter_key -N ""

# Add public key to repo deploy keys (Settings → Deploy Keys)
# - Title: "Documenter"
# - Key: contents of documenter_key.pub
# - Check "Allow write access"

# Add private key to repo secrets (Settings → Secrets → Actions)
# - Name: DOCUMENTER_KEY
# - Value: contents of documenter_key (entire file)
```

### Configure Codecov (Optional)

1. Visit https://codecov.io/
2. Link your GitHub account
3. Enable repository
4. Copy token
5. Add as secret: `CODECOV_TOKEN`

## Local Development

### Run Tests

```bash
# All tests
julia --project -e 'using Pkg; Pkg.test()'

# Typst backend tests
TYPST_PLATFORM=typst julia --project=test/typst_backend test/typst_backend/runtests.jl
```

### Format Code

```bash
just format
# or
julia -e 'using Pkg; Pkg.add("Runic"); using Runic; Runic.main(["--inplace", "."])'
```

### Check Spelling

```bash
# Install typos
cargo install typos-cli

# Check
typos

# Fix
typos --write-changes
```

### Build Docs

```bash
# HTML
just docs

# With link checking
julia --project=docs docs/make.jl linkcheck

# Typst/PDF
just docs-typst
```

## CI Best Practices

### 1. Fast Feedback

- Quality checks run first (formatting, spelling)
- Parallel test execution
- Strategic platform exclusions

### 2. Comprehensive Coverage

- Multiple Julia versions
- Multiple platforms
- Backend-specific tests

### 3. Resource Efficiency

- Concurrency control prevents waste
- Caching reduces build times
- Strategic `continue-on-error` for nightly

### 4. Maintainability

- Clear job names
- Extensive comments
- Modular structure

## Debugging CI Failures

### Formatting Failures

```bash
# Check what would change
just format

# Apply fixes
git add -A
git commit -m "Apply formatting"
```

### Typos Failures

```bash
typos
# If false positive, add to .typos.toml [default.extend-words]
```

### Typst Backend Failures

```bash
# Run locally with specific platform
TYPST_PLATFORM=native julia --project=test/typst_backend test/typst_backend/runtests.jl

# Check artifacts in CI (uploaded for 7 days)
```

### Linkcheck Failures

- Check URL is valid
- Might be temporary network issue
- Add to `linkcheck_ignore` if necessary

## Comparison with Documenter.jl CI

### Similarities

✅ Runic formatting
✅ Typos spell checking
✅ Prettier formatting
✅ Multi-platform testing
✅ Coveralls parallel submission
✅ Documentation deployment
✅ Linkcheck
✅ Changelog enforcement

### Differences

- ⚠️ **No LaTeX backend tests** (DocumenterTypst doesn't use LaTeX)
- ✅ **Typst backend tests** (DocumenterTypst-specific)
- ⚠️ **No prerender tests** (DocumenterTypst doesn't use NodeJS)
- ⚠️ **No themes tests** (DocumenterTypst doesn't use CSS themes)
- ⚠️ **No search benchmarks** (DocumenterTypst doesn't implement search)

### Typst-Specific Additions

- Platform-specific testing (`typst`, `native`, `docker`, `none`)
- Artifact uploads for `.typ` and `.pdf` files
- Multi-backend verification

## Maintenance

### Updating Actions

Check for new versions periodically:

- `actions/checkout@v6`
- `julia-actions/setup-julia@v2`
- `julia-actions/cache@v2`
- `codecov/codecov-action@v5`
- `fredrikekre/runic-action@v1`

### Updating Julia Versions

- Update minimum version when bumping compat
- Keep nightly for early warning
- Test on LTS versions

### Updating Runic/Prettier/Typos

- Runic: Update `version` in `runic-action`
- Prettier: Update `actionsx/prettier` version
- Typos: Update `crate-ci/typos` (tracks `master`)
