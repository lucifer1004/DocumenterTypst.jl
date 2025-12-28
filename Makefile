# Makefile for DocumenterTypst.jl development tasks

.PHONY: help test format docs changelog clean

help:
	@echo "Available targets:"
	@echo "  test       - Run test suite"
	@echo "  format     - Format code with JuliaFormatter"
	@echo "  docs       - Build HTML documentation"
	@echo "  docs-typst - Build Typst/PDF documentation"
	@echo "  changelog  - Generate changelog for docs"
	@echo "  clean      - Clean build artifacts"
	@echo "  dev        - Install package in dev mode"

test:
	julia --project -e 'using Pkg; Pkg.test()'

format:
	julia -e 'using JuliaFormatter; format(".", verbose=true)'

docs:
	julia --project=docs -e '\
		using Pkg; \
		Pkg.develop(PackageSpec(path=pwd())); \
		Pkg.instantiate(); \
		include("docs/make.jl")'

docs-typst:
	julia --project=docs -e '\
		using Pkg; \
		Pkg.develop(PackageSpec(path=pwd())); \
		Pkg.instantiate()' && \
	julia --project=docs docs/make.jl typst

docs-typst-native:
	julia --project=docs -e '\
		using Pkg; \
		Pkg.develop(PackageSpec(path=pwd())); \
		Pkg.instantiate()' && \
	julia --project=docs docs/make.jl typst native

docs-typst-source:
	julia --project=docs -e '\
		using Pkg; \
		Pkg.develop(PackageSpec(path=pwd())); \
		Pkg.instantiate()' && \
	julia --project=docs docs/make.jl typst none

changelog:
	julia --project=docs -e '\
		using Pkg; \
		Pkg.instantiate(); \
		include("docs/changelog.jl")'

clean:
	rm -rf docs/build docs/build-typst
	rm -rf docs/src/release-notes.md
	find . -name "*.jl.*.cov" -delete
	find . -name "*.jl.cov" -delete
	find . -name "*.jl.mem" -delete

dev:
	julia --project -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'

.PHONY: ci-test
ci-test:
	julia --project -e 'using Pkg; Pkg.test(coverage=true)'
