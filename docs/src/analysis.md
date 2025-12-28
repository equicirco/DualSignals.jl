# Analysis utilities

The analysis layer turns raw duals, activity, and slack into ranked insights.
It focuses on identifying binding constraints and highlighting the largest
marginal values that matter for policy decisions.

## Bindingness

`bindingness(dataset; tol=1e-6)` returns a row per constraint solution with:

- inferred slack (from activity and RHS, if available)
- inferred binding flag (within tolerance)
- dual values and metadata
- `impact` (policy interpretation of the dual sign)

If slack or activity is missing, the binding flag remains `nothing`.

## Rankings

`rank_constraints(dataset; metric=:abs_dual, top=10, binding_only=false, ...)`
returns the top constraints by a chosen metric:

- `:abs_dual` (default) ranks by |dual|
- `:dual` ranks by signed dual
- `:dual_times_slack` ranks by |dual| × |slack|

Use filters like `kind`, `time`, `scenario`, and `binding_only=true` for focused
views (e.g., only capacity constraints that are binding).

Ranked rows include an `impact` field that interprets the dual sign in
policy terms (e.g., whether increasing a RHS relaxes or tightens the objective),
based on objective sense and constraint sense.

### Additional metrics

You can also use:

- `:dual_times_binding_duration` to prioritize constraints that are binding for
  many time steps (for time-indexed data).
- `:dual_times_slack_change` to evaluate a small relaxation, e.g.
  `rank_constraints(...; metric=:dual_times_slack_change, slack_change=0.1)`.

## Aggregation

`aggregate_duals(dataset; by=:kind)` summarizes duals across groups and returns
counts plus mean/mean-absolute/max-absolute duals.

`aggregate_duals_series(dataset; by=:constraint_id, over=:time)` summarizes duals
over time or scenario to support time-series reporting.
