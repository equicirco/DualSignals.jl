"""
Return a ranked table of top constraints by the chosen metric.

Keywords:
- `metric`: `:abs_dual`, `:dual`, `:dual_times_slack`, `:dual_times_binding_duration`,
  or `:dual_times_slack_change`.
- `top`: number of rows to return.
- `tol`: tolerance for binding status.
- `binding_only`: if true, return only binding constraints.
"""
function table_top_constraints(
    dataset::DualSignalsDataset;
    metric::Symbol=:abs_dual,
    top::Int=10,
    tol::Float64=1e-6,
    binding_only::Bool=true,
)
    rows = rank_constraints(
        dataset;
        metric=metric,
        top=top,
        tol=tol,
        binding_only=binding_only,
    )
    return rows
end

function _annotate_rows(dataset::DualSignalsDataset, rows)
    return [(; row..., impact=_impact_label(dataset.metadata.objective_sense, row.sense, row.dual)) for row in rows]
end

"""
Return a bundle of tables for bottlenecks and capacity priorities.

Keywords:
- `top`: number of rows per table.
- `tol`: tolerance for binding status.
- `with_impact`: include human-readable impact labels.
- `slack_change`: delta slack for relaxation-value metric.
- `include_duration`: include time-weighted bottlenecks (`:auto` or Bool).
- `include_slack_change`: include relaxation value (`:auto` or Bool).
"""
function table_policy_priorities(
    dataset::DualSignalsDataset;
    top::Int=5,
    tol::Float64=1e-6,
    with_impact::Bool=false,
    slack_change=nothing,
    include_duration=:auto,
    include_slack_change=:auto,
)
    bottlenecks = rank_constraints(
        dataset;
        metric=:abs_dual,
        top=top,
        tol=tol,
        binding_only=true,
    )

    capacity = rank_constraints(
        dataset;
        metric=:abs_dual,
        top=top,
        tol=tol,
        binding_only=true,
        kind=DualSignals.capacity,
    )

    extras = Dict{Symbol, Any}()
    use_duration = include_duration === :auto ? any(s.time !== nothing for s in dataset.constraint_solutions) : include_duration
    if use_duration
        extras[:time_weighted_bottlenecks] = rank_constraints(
            dataset;
            metric=:dual_times_binding_duration,
            top=top,
            tol=tol,
            binding_only=true,
        )
    end
    use_slack_change = include_slack_change === :auto ? slack_change !== nothing : include_slack_change
    if use_slack_change
        if slack_change === nothing
            error("slack_change must be provided when include_slack_change=true.")
        end
        extras[:relaxation_value] = rank_constraints(
            dataset;
            metric=:dual_times_slack_change,
            slack_change=slack_change,
            top=top,
            tol=tol,
            binding_only=true,
        )
    end

    base = if with_impact
        (
            bottlenecks=_annotate_rows(dataset, bottlenecks),
            capacity_expansions=_annotate_rows(dataset, capacity),
        )
    else
        (bottlenecks=bottlenecks, capacity_expansions=capacity)
    end
    if isempty(extras)
        return base
    end
    result = Dict{Symbol, Any}(
        :bottlenecks => base.bottlenecks,
        :capacity_expansions => base.capacity_expansions,
    )
    for (k, v) in extras
        result[k] = v
    end
    return result
end
