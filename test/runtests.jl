# ============================================================================
# DEPRECATED: Main test entry point (for Pkg.test() compatibility)
# ============================================================================
#
# This file is kept for backward compatibility with `Pkg.test()`.
# However, tests should now be run individually:
#
#   - Unit tests:        julia --project=. test/run_unit_tests.jl
#   - Integration tests: julia --project=test/integration test/integration/runtests.jl
#   - Snapshot tests:    julia --project=. test/run_snapshot_tests.jl
#
# In CI, tests run independently for better parallelization and clearer reporting.
#
# For local development:
#   just test-unit           # Fast unit tests
#   just test-integration    # Integration tests
#   just test-snapshot       # Snapshot tests
#   just test                # Run common tests (unit + snapshot)
#
# ============================================================================

@warn """
Running tests via Pkg.test() or test/runtests.jl is deprecated.
Please use individual test runners for better performance:
  - julia --project=. test/run_unit_tests.jl
  - julia --project=. test/run_snapshot_tests.jl
  - julia --project=test/integration test/integration/runtests.jl

Or use just commands:
  - just test-unit
  - just test-snapshot
  - just test-integration
"""

# For now, run unit tests only (fast, covers most functionality)
# This ensures Pkg.test() still works but is fast
include("run_unit_tests.jl")

# Note: Integration and snapshot tests are not run here to keep Pkg.test() fast.
# Run them explicitly if needed:
#   julia --project=test/integration test/integration/runtests.jl
#   julia --project=. test/run_snapshot_tests.jl
