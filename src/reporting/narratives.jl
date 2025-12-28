"""
Generate a short narrative summary of top bottlenecks.

Keywords:
- `top`: number of bottlenecks to include.
- `tol`: tolerance for binding status.
"""
function narrative_top_bottlenecks(
    dataset::DualSignalsDataset;
    top::Int=5,
    tol::Float64=1e-6,
)
    rows = rank_constraints(dataset; metric=:abs_dual, top=top, tol=tol, binding_only=true)
    if isempty(rows)
        return "No binding constraints found with available duals."
    end

    parts = String[]
    for (idx, row) in enumerate(rows)
        comp = isempty(row.component_ids) ? "unknown" : join(row.component_ids, ",")
        push!(parts, "$(idx)) $(row.constraint_id) [$(row.kind)] on $(comp) with dual $(round(row.dual, digits=4))")
    end

    return "Top bottlenecks by absolute dual: " * join(parts, "; ")
end

"""
Generate a narrative policy summary with optional extras.

Keywords:
- `top`: number of rows per summary section.
- `tol`: tolerance for binding status.
- `slack_change`: delta slack for relaxation-value metric.
- `include_duration`: include time-weighted bottlenecks (`:auto` or Bool).
- `include_slack_change`: include relaxation value (`:auto` or Bool).
"""
function narrative_policy_summary(
    dataset::DualSignalsDataset;
    top::Int=3,
    tol::Float64=1e-6,
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

    duration_text = ""
    use_duration = include_duration === :auto ? any(s.time !== nothing for s in dataset.constraint_solutions) : include_duration
    if use_duration
        duration = rank_constraints(
            dataset;
            metric=:dual_times_binding_duration,
            top=top,
            tol=tol,
            binding_only=true,
        )
        duration_text = if isempty(duration)
            " No time-weighted bottlenecks available."
        else
            items = join(
                ["$(i)) $(row.constraint_id) (score=$(round(row.metric, digits=4)))" for (i, row) in enumerate(duration)],
                "; "
            )
            " Time-weighted bottlenecks: $(items)."
        end
    end

    slack_text = ""
    use_slack_change = include_slack_change === :auto ? slack_change !== nothing : include_slack_change
    if use_slack_change
        if slack_change === nothing
            error("slack_change must be provided when include_slack_change=true.")
        end
        slack_rank = rank_constraints(
            dataset;
            metric=:dual_times_slack_change,
            slack_change=slack_change,
            top=top,
            tol=tol,
            binding_only=true,
        )
        slack_text = if isempty(slack_rank)
            " No relaxation-value results available."
        else
            items = join(
                ["$(i)) $(row.constraint_id) (score=$(round(row.metric, digits=4)))" for (i, row) in enumerate(slack_rank)],
                "; "
            )
            " Relaxation value (Δ slack=$(slack_change)): $(items)."
        end
    end

    bottleneck_text = if isempty(bottlenecks)
        "No binding constraints with duals available."
    else
        join(
            ["$(i)) $(row.constraint_id) (|dual|=$(round(abs(row.dual), digits=4)), $(_impact_label(dataset.metadata.objective_sense, row.sense, row.dual)))" for (i, row) in enumerate(bottlenecks)],
            "; "
        )
    end

    capacity_text = if isempty(capacity)
        "No binding capacity constraints with duals available."
    else
        join(
            ["$(i)) $(row.constraint_id) (|dual|=$(round(abs(row.dual), digits=4)), $(_impact_label(dataset.metadata.objective_sense, row.sense, row.dual)))" for (i, row) in enumerate(capacity)],
            "; "
        )
    end

    return "Policy summary. Top bottlenecks: $(bottleneck_text). " *
           "Top capacity constraints to relax: $(capacity_text)." *
           duration_text * slack_text
end
