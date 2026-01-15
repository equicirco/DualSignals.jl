# DualSignals.jl Changelog
All notable changes to this project will be documented in this file.
Releases use semantic versioning as in 'MAJOR.MINOR.PATCH'.
## Change entries
Added: For new features that have been added.
Changed: For changes in existing functionality.
Deprecated: For once-stable features removed in upcoming releases.
Removed: For features removed in this release.
Fixed: For any bug fixes.
Security: For vulnerabilities.

## [0.1.2] - 2026-01-15
### Changed
- Expanded Julia compat to 1.10
### Fixed
- Resolved enum name collision by renaming `ConstraintKind.other` to `ConstraintKind.other_constraint` (still serialized as `other`)
### Added
- CI/CD for Julia Registry deployment of updates

## [0.1.1] - 2025-12-28
### Added
- Registration in Julia General Registry
- Installation instructions

## [0.1.0] - 2025-12-27
### Added
- Repo structure
- Data model and basic io code and validation
- Constraint tagging in the data model plus CSV/Arrow support
- JuMP adapter hooks for constraint tags
- Example analyses with tables and plots in docs
- Docs navigation refresh and expanded landing page
