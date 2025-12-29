# Snapshot Tests

This directory contains snapshot files for DocumenterTypst output testing.

## What Are Snapshots?

Snapshots are saved reference outputs for Typst code generation. Each `.typ` file represents the expected output for a specific test case.

## Why Snapshots?

1. **Catch Regressions**: Any unintended change in output is detected immediately
2. **Human Readable**: `.typ` files can be reviewed in code review
3. **Easy Maintenance**: Update all snapshots with one command

## How They Work

```julia
test_snapshot("test_name", "# Markdown input")
```

1. Converts Markdown → Typst
2. Compares output to `test_name.typ`
3. Fails if different, showing diff

## Updating Snapshots

When you intentionally change Typst output:

```bash
# Update all snapshots
UPDATE_SNAPSHOTS=1 julia --project=. test/runtests.jl

# Or using just
just test-snapshot-update
```

## Adding New Snapshots

Add to `test/runtests.jl`:

```julia
@testset "My Feature" begin
    test_snapshot("my_test", "# Test markdown"; update)
end
```

Run once with `UPDATE_SNAPSHOTS=1` to create the snapshot.

## Git Workflow

- **DO commit** snapshot files
- **DO review** snapshot changes in PRs
- **DON'T** manually edit snapshots (regenerate instead)

## File Format

All snapshots are normalized:

- No timestamps
- No temporary paths
- Consistent line endings
- Trimmed whitespace

This ensures stable comparisons across environments.
