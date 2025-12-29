# Jujutsu PR Workflow

**Quick guide for Pull Requests with Jujutsu version control.**

---

## 0. Prerequisites

Verify Jujutsu repository (tools may hide dotfiles):

```bash
ls -la | grep "\.jj"
```

Expected: `.jj` directory exists. If not, use Git workflow instead.

---

## 1. Create & Push Feature

### Start New Feature

**⚠️ User confirmation required before running:**

```bash
# Check status
jj st
jj log --limit 3

# Create new change
jj new trunk() -m "feat: your feature description"
jj bookmark create my-feature

# Make changes, then push
jj git push --bookmark my-feature
```

### Create PR

Open URL from push output, or:

```bash
gh pr create --head my-feature --base main --web
```

---

## 2. Update After Review

### Small Changes (Recommended)

**⚠️ User confirmation required:**

```bash
# Edit files directly
jj describe  # Optional: update commit message
jj git push --bookmark my-feature
```

### Large Changes

**⚠️ User confirmation required:**

```bash
jj new              # Create change on top
# Make changes...
jj squash           # Merge into parent
jj git push --bookmark my-feature
```

---

## 3. Clean Up After Merge

### Sync & Verify

**⚠️ User confirmation required:**

```bash
jj git fetch        # Sync from GitHub
jj log --limit 5    # Verify trunk includes your changes
jj st               # Check working copy status
```

### Case A: Clean Working Copy

**⚠️ User confirmation required:**

```bash
jj new trunk()                  # Switch to trunk
jj bookmark delete my-feature   # Delete bookmark
jj abandon <OLD_COMMIT_HASH>    # Clean up (get hash from jj log)
jj git push --deleted           # Optional: delete remote branch
```

### Case B: Have New Uncommitted Work

**⚠️ User confirmation required:**

```bash
jj new trunk() -m "feat: next feature"
jj bookmark create next-feature
jj bookmark delete my-feature
jj abandon <OLD_COMMIT_HASH>
```

---

## Quick Reference

### Essential Commands

```bash
# Status
jj st                              # Working copy status
jj log --limit 5                   # Recent history
jj bookmark list                   # List bookmarks

# Create & Update
jj new trunk() -m "message"        # New change from trunk
jj bookmark create NAME            # Create bookmark
jj describe                        # Edit commit message
jj squash                          # Merge into parent

# Sync
jj git fetch                       # Pull from remote
jj git push --bookmark NAME        # Push
jj git push --bookmark NAME -f     # Force push

# Cleanup
jj bookmark delete NAME            # Delete bookmark
jj abandon <HASH>                  # Remove commit (use hash, not change ID!)
jj git push --deleted              # Delete remote branches
```

### Safety Rules

| ✅ Do                              | ❌ Don't             |
| ---------------------------------- | -------------------- |
| Use `--bookmark NAME` when pushing | Use `--all`          |
| Abandon by commit **hash**         | Abandon by change ID |
| Check `jj st` before operations    | Blindly run commands |
| Use `jj log` frequently            | Forget where you are |

---

## Common Issues

| Problem                    | Solution                                                      |
| -------------------------- | ------------------------------------------------------------- |
| `gh`: "not on any branch"  | Use `--head my-feature --base main`                           |
| "Commit is immutable"      | Don't abandon commits on trunk; use commit hash not change ID |
| "Working copy has changes" | Jujutsu auto-handles this; changes move with you              |
| Forgot to create bookmark  | `jj bookmark create NAME` then push                           |

---

## Jujutsu vs Git

| Task           | Git                       | Jujutsu                                                |
| -------------- | ------------------------- | ------------------------------------------------------ |
| Create feature | `git checkout -b feat`    | `jj new trunk() -m "feat"` + `jj bookmark create feat` |
| Commit         | `git add . && git commit` | Auto-tracked                                           |
| Amend          | `git commit --amend`      | `jj describe` (anytime)                                |
| Push           | `git push`                | `jj git push --bookmark feat`                          |
| Update PR      | `git push -f`             | `jj git push --bookmark feat -f`                       |
| Fetch          | `git fetch`               | `jj git fetch`                                         |
| Switch         | `git checkout main`       | `jj new trunk()`                                       |

**Key difference**: Jujutsu auto-tracks working directory. No staging area.

---

## Troubleshooting

### Nuclear Option (⚠️ Only if broken)

```bash
jj cleanup --dry-run  # Preview
jj cleanup            # Clean orphans
```

### Get Help

```bash
jj help              # General
jj help <command>    # Specific command
```

### Git Interop

Git commands still work if needed:

```bash
git status
git log
```

---

**Always verify with `jj st` and `jj log` before and after operations!**
