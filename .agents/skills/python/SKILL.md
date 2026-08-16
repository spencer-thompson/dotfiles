---
name: python
description: >-
  Use when editing, writing, or validating Python code, tests, packaging,
  pyproject.toml, Python tooling, or quality checks.
---

# Python

## Toolchain Precedence

- Inspect `pyproject.toml`, lockfiles, tool configuration, CI workflows, project scripts, tests, and repository guidance
  before choosing commands.
- Treat explicit repository instructions and commands invoked by CI or project scripts as authoritative. Use committed
  configuration and lockfiles as supporting evidence.
- Preserve the actively declared tool in each role. When evidence conflicts, prefer repository instructions and invoked
  CI or project commands over orphaned configuration. Do not migrate or add a competing package manager, formatter,
  linter, type checker, or test runner unless the user asks.
- For each role the repository does not fill, use the defaults:
  - `uv` for Python versions, environments, dependencies, lockfiles, and command execution
  - Ruff for linting and formatting
  - ty for type checking
- Use project-owned scripts and CI-equivalent commands when available.

## uv, Ruff, and ty

- Initialize new projects with `uv init`. Manage dependencies with `uv add` and `uv remove`; synchronize and lock with
  `uv sync` and `uv lock`.
- In uv projects, run declared project tools with `uv run <command>` so they use the project environment. Use
  `uv run --locked <command>` for reproducible validation and fail when the lockfile is stale.
- Use `uvx <tool>` for a one-off check that the project does not own. Add recurring contributor or CI tools to the
  repository's development dependencies instead of relying on hidden global setup.
- Use Ruff for both linting and formatting. Preserve existing Ruff configuration; without configuration, use Ruff's
  stable defaults instead of enabling a broad or preview rule set.
- Apply Ruff's safe fixes by default. Review unsafe fixes and dead-code deletions against intended behavior and tests.
- Use exactly one type checker. Preserve mypy, Pyright, basedpyright, or another declared checker; otherwise use ty.
- Do not conceal findings with blanket `noqa`, `type: ignore`, exclusions, or generated baselines. Use the narrowest
  specific suppression and explain non-obvious exceptions.

## Readable, Pythonic Python

- Prefer direct code that can be read from top to bottom: explicit names, simple control flow, clear return values, and
  module functions before single-use classes.
- Use the standard library before adding dependencies. Use language features such as context managers, dataclasses,
  enums, protocols, and `pathlib` only when they make the code clearer.
- Add type hints where they clarify contracts, especially public APIs and non-obvious data structures.
- Preserve the supported Python version. Use modern syntax only when the project supports it.
- Avoid broad exceptions, import-time side effects, hidden global state, wildcard imports, and premature class
  hierarchies.

### Resist Helper Extraction

- Keep single-use logic inline when it reads clearly at the call site.
- Do not create a helper function or private `_helper` merely to shorten a function, label a few straightforward lines,
  remove minor duplication, or make the code look decomposed.
- Extract a helper only when it creates a real conceptual boundary, centralizes substantial shared logic, isolates a
  tricky invariant or side effect, or makes the caller materially easier to understand despite the added indirection.
- A helper must have a clear name and contract. If the reader has to jump to another definition without gaining a
  simpler mental model, keep the code inline.
- Do not turn this preference into long, tangled functions. Split code at genuine conceptual boundaries, not arbitrary
  size thresholds.

## Tests and Core Validation

- Add or update focused behavioral tests for behavior changes. Preserve the repository's test runner; use pytest when
  the repository has no declared alternative.
- Before handoff, run every applicable configured core check: tests, lint, formatting, and the single selected type
  checker. Use project-owned commands when declared. For a repository without declared tools, use:
  - `uv run --with pytest pytest` when tests exist
  - `uvx ruff check .`
  - `uv format --check`
  - `uv check --locked`
- Run Ruff fixes before formatting, then run lint again.
- Report exactly which checks ran and any failures or unavailable checks.

## Specialized Checks

Specialized tools are not default quality gates. Use one only when the repository already requires it or the task
explicitly asks the question it answers.

- Use branch coverage for explicit test-gap or control-flow analysis. Coverage measures execution, not correctness.
- Use Vulture only for an explicit dead-code investigation. Treat every result as a candidate and inspect dynamic use,
  decorators, registries, reflection, entry points, tests, and references before deleting code.
- Use deptry for explicit dependency-declaration drift and `uv audit --locked` for dependency security or release work.
- Use a profiler against a representative workload when performance is in scope. Static checks do not identify runtime
  CPU or memory hotspots.

## Configuration and Documentation

- Prefer `pyproject.toml` unless the repository already uses dedicated configuration files.
- Keep configuration focused on project decisions; do not dump broad default rule sets into the repository.
- Check current official documentation or Context7 for version-sensitive library, framework, and tool behavior.
