# Check Documentation Updates

**Detect code changes and suggest related documentation updates.**

---

## What This Does

1. Finds modified files via Jujutsu (`jj status`)
2. Maps code changes to related documentation
3. Suggests specific docs that may need updates

**Philosophy**: Simple pattern matching. No AST parsing. No magic.

---

## Usage

### Quick Check (Recommended)

```bash
jj status
```

Then review mapping below to identify docs manually.

### Automated Suggestion

Run this command, and I'll:

1. Execute `jj status`
2. Apply mapping rules
3. Show specific documentation files to review

---

## Mapping Rules

### Source Code Changes

| Changed Pattern          | Check These Docs                                     | Why                           |
| ------------------------ | ---------------------------------------------------- | ----------------------------- |
| `src/DocumenterTypst.jl` | `docs/src/api/reference.md`                          | Public API                    |
| `src/TypstWriter/*.jl`   | `docs/src/api/reference.md`                          | Core implementation           |
| `assets/documenter.typ`  | `docs/src/manual/styling.md`                         | Template changes              |
| `assets/typst/*.svg`     | `docs/src/manual/styling.md`                         | Asset references              |
| `Project.toml` (version) | `docs/src/manual/getting_started.md`, `CHANGELOG.md` | Version-specific instructions |
| `Project.toml` (deps)    | `docs/src/manual/troubleshooting.md`                 | Dependency issues             |

### Test Changes

| Changed Pattern              | Check These Docs                             | Why                |
| ---------------------------- | -------------------------------------------- | ------------------ |
| `test/integration/fixtures/` | `docs/src/examples/*.md`                     | Example code       |
| `test/snapshots/`            | Usually no doc change needed                 | Internal test data |
| `test/*.jl` (new test)       | May need new example in `docs/src/examples/` | Feature coverage   |

### Configuration Changes

| Changed Pattern           | Check These Docs                                  | Why                |
| ------------------------- | ------------------------------------------------- | ------------------ |
| `justfile`                | `AGENTS.md`, `docs/src/manual/getting_started.md` | Developer workflow |
| `.github/workflows/*.yml` | `.github/workflows/README.md`                     | CI/CD docs         |
| `scripts/*.jl`            | `scripts/README.md`                               | Script usage       |

### Documentation-Only Changes

| Changed Pattern    | Check These Docs                | Why                          |
| ------------------ | ------------------------------- | ---------------------------- |
| `docs/src/**/*.md` | None (docs already updated)     | Self-contained               |
| `CHANGELOG.md`     | None                            | Changelog is source of truth |
| `README.md`        | May sync to `docs/src/index.md` | Keep in sync                 |

---

## Critical Rules (From AGENTS.md)

1. **New Features**: MUST update `CHANGELOG.md` under "Unreleased"
2. **API Changes**: MUST update `docs/src/api/reference.md`
3. **Breaking Changes**: MUST update:
   - `CHANGELOG.md` (prominently marked)
   - `docs/src/manual/getting_started.md` (migration guide)
   - `docs/src/release-notes.md`

---

## Example Workflow

### Scenario: You changed `src/TypstWriter/ast_conversion.jl`

**Step 1: Check status**

```bash
jj status
```

**Step 2: Consult mapping**

- Source code changed → Check `docs/src/api/reference.md`
- If you added new node support → Add example to `docs/src/examples/advanced.md`

**Step 3: Verify CHANGELOG**

```bash
grep -A 5 "Unreleased" CHANGELOG.md
```

If your change is user-visible, add an entry.

**Step 4: Test docs build**

```bash
just docs          # HTML
just docs-typst    # PDF
```

---

## When to Skip Documentation

**Skip if**:

- Internal refactoring (no behavior change)
- Test-only changes (no new features)
- Typo fixes in comments

**Always update if**:

- New public API
- Changed behavior (even minor)
- New configuration option
- Performance improvements (users care!)

---

## Implementation Notes

### Why Pattern Matching (Not AST Analysis)?

**Linus-style reasoning**:

- Problem: Know which docs to check
- Overkill: Parse Julia AST to find changed exports
- Reality: File path tells you enough

**Data structure**: Path pattern → doc list (simple map)
**Complexity**: O(n) where n = changed files (trivial)
**Maintenance**: Add one line when adding new module

### Why Manual Review?

No tool can determine if docs are "correct" - that requires human judgment.

This command tells you **where to look**, not **what to write**.

---

## Quick Reference

```bash
# Check what changed
jj status
jj diff

# Build and verify docs
just docs
just docs-typst

# Common doc locations
docs/src/api/reference.md           # API reference
docs/src/manual/*.md                # User guides
docs/src/examples/*.md              # Examples
CHANGELOG.md                        # Release notes
README.md                           # Project overview
AGENTS.md                           # AI/contributor guide
```

---

## Integration with PR Workflow

**Before `jj git push`**:

1. Run this command
2. Review suggested docs
3. Update if needed
4. Run `just docs` to verify
5. Add CHANGELOG entry if user-visible
6. Push everything together

**Why**: Docs and code should be atomic in PRs.

---

**Remember**: This is a suggestion tool, not a judge. Use your brain. If a change is obvious (like fixing a typo), don't overthink it.
