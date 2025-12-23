# Roadmap

## Goal
Provide a domain-agnostic Julia toolkit to extract, standardize, and present dual-based “signals” (shadow prices) from solved models (network optimization, equilibrium/CGE, IO-LP), using a simple, portable data model.

## Core principles
- Inputs are **model-agnostic**: constraints, duals, primal activity/slack, units, and component mapping.
- Outputs are **decision-support**: rankings, bottlenecks, marginal values of relaxations, and clear summaries.
- Minimal assumptions; explicit sign conventions and units everywhere.

## Milestone 0 — Repository + CI
- Skeleton package structure
- Basic CI (tests + formatting)
- Docs build pipeline

## Milestone 1 — Data model v0.1
- Define canonical schema (JSON) for:
  - Components
  - Constraints
  - Solution (duals, activity, slack)
  - Optional variables (flows/outputs)
- Julia types mirroring the schema
- Import/export: JSON and CSV (Arrow optional)
- Validation: required fields, units presence, simple consistency checks

## Milestone 2 — Generic dual analytics v0.1
- Bindingness detection (active constraints, tolerance handling)
- Rankings:
  - by |dual|
  - by “dual × binding duration” (time-indexed cases)
  - by “dual × slack change” (what-if small relaxation)
- Aggregations across time and scenarios
- Clear sign conventions:
  - minimization vs maximization
  - ≤ / ≥ constraint senses

## Milestone 3 — Reporting v0.1
- Tables suitable for non-experts:
  - “Top bottlenecks”
  - “Most valuable capacity expansions”
  - “Most costly policy caps”
- Plain-language narrative generator (short, templated)
- Basic plotting hooks (leave styling to user)

## Milestone 4 — JuMP/MOI adapter v0.1
- Export helpers to build the data model from JuMP solutions:
  - constraint names/IDs
  - duals
  - constraint activity/slack
  - variable values (optional)
- Examples:
  - toy network
  - capacity-constrained production
- Document limitations (solver dual availability, constraint types)

## Milestone 5 — Domain packs (optional)
- Power-style: node balance → nodal prices; link capacity → congestion signals
- IO-LP style: product balance duals → shadow values of outputs
- CGE/MCP style: mapping conventions for equilibrium constraints (as available)

## Release plan
- v0.1.0: schema + IO + core analytics + minimal docs
- v0.2.0: reporting + JuMP adapter
- v0.3.0: richer validations + scenario/time aggregation + domain packs

## Definition of done for v0.1.0
- Schema documented and stable
- Round-trip JSON import/export
- Rankings and bindingness utilities with tests
- One worked example in docs with reproducible output
