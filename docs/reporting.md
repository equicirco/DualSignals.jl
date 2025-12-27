---
title: Reporting
nav_order: 7
---

# Reporting utilities

Reporting helpers wrap analysis output into policy-friendly tables and short
plain-language summaries. They are intentionally compact so you can reuse the
results in dashboards, reports, or narrative briefs.

## Tables

`table_top_constraints(dataset; metric=:abs_dual, top=10, binding_only=true)`
returns the top constraints ranked by the chosen metric.

`table_policy_priorities(dataset; top=5)` returns two lists:

- `bottlenecks`: top binding constraints by |dual|
- `capacity_expansions`: top binding capacity constraints by |dual|

These lists are the basis for “top bottlenecks” and “most valuable expansions.”

Use `with_impact=true` to add an `impact` field that interprets dual signs
relative to the objective sense (minimize vs maximize) and constraint sense:

- `le`: impact refers to increasing the RHS
- `ge`: impact refers to decreasing the RHS
- `eq`: impact refers to relaxing the equality

This assumes duals follow the standard convention where they represent the
marginal objective change from relaxing a constraint.

Optional sections (auto-enabled when applicable):

- `include_duration=:auto` (default) adds `time_weighted_bottlenecks` when time
  values are present, using `:dual_times_binding_duration`.
- `include_slack_change=:auto` (default) adds `relaxation_value` when
  `slack_change` is provided, using `:dual_times_slack_change`.

## Narratives

`narrative_top_bottlenecks(dataset; top=5)` returns a single sentence listing
the largest binding constraints by absolute dual.

`narrative_policy_summary(dataset; top=3)` returns a short summary combining
general bottlenecks and capacity expansions, including an interpretation of the
dual sign when objective sense is available.

Pass `include_duration=true` and/or `include_slack_change=true` to append
time-weighted bottlenecks or relaxation-value summaries.
