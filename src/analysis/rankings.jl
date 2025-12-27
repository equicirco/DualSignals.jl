function _metric_value(metric::Symbol, dual::Float64, slack)
    if metric == :abs_dual
        return abs(dual)
    elseif metric == :dual
        return dual
    elseif metric == :dual_times_slack
        if slack === nothing
            return nothing
        end
        return abs(dual) * abs(slack)
    end
    error("Unknown metric: $(metric)")
end

function _is_binding_from_slack(slack, tol::Float64)
    if slack === nothing
        return false
    end
    return abs(slack) <= tol
end

function _time_to_numeric(t)
    if t === nothing
        return nothing
    end
    try
        return Float64(t)
    catch
        return nothing
    end
end

function _sort_time_values(times)
    parsed = [(t, _time_to_numeric(t)) for t in times]
    if all(p[2] !== nothing for p in parsed)
        sort!(parsed, by=x -> x[2])
    else
        sort!(parsed, by=x -> string(x[1]))
    end
    return [p[1] for p in parsed]
end

function _binding_duration_map(dataset::DualSignalsDataset; tol::Float64=1e-6)
    constraints = Dict(c.constraint_id => c for c in dataset.constraints)
    by_id_time = Dict{String, Vector{Tuple{Any, Bool}}}()

    for sol in dataset.constraint_solutions
        constraint = get(constraints, sol.constraint_id, nothing)
        if constraint === nothing
            continue
        end
        slack = _infer_slack(constraint, sol)
        bound = _infer_binding(constraint, sol, tol)
        is_bound = bound === true || _is_binding_from_slack(slack, tol)
        rows = get!(by_id_time, sol.constraint_id, Tuple{Any, Bool}[])
        push!(rows, (sol.time, is_bound))
    end

    duration = Dict{String, Float64}()
    for (cid, rows) in by_id_time
        times = [r[1] for r in rows]
        if any(t === nothing for t in times)
            duration[cid] = sum(r[2] for r in rows)
            continue
        end
        ordered = _sort_time_values(times)
        total = 0.0
        for t in ordered
            bound = first(r[2] for r in rows if r[1] == t)
            if bound
                total += 1.0
            end
        end
        duration[cid] = total
    end
    return duration
end


function rank_constraints(
    dataset::DualSignalsDataset;
    metric::Symbol=:abs_dual,
    top::Int=10,
    kind=nothing,
    scenario=nothing,
    time=nothing,
    tol::Float64=1e-6,
    binding_only::Bool=false,
    slack_change=nothing,
)
    constraints = Dict(c.constraint_id => c for c in dataset.constraints)
    objective_sense = dataset.metadata.objective_sense
    duration = metric == :dual_times_binding_duration ?
        _binding_duration_map(dataset; tol=tol) : Dict{String, Float64}()
    rows = Vector{NamedTuple}()

    for sol in dataset.constraint_solutions
        if scenario !== nothing && sol.scenario != scenario
            continue
        end
        if time !== nothing && sol.time != time
            continue
        end
        constraint = get(constraints, sol.constraint_id, nothing)
        if constraint === nothing
            continue
        end
        if kind !== nothing && constraint.kind != kind
            continue
        end
        slack = _infer_slack(constraint, sol)
        is_binding = _infer_binding(constraint, sol, tol)
        if binding_only && is_binding != true
            continue
        end
        value = if metric == :dual_times_binding_duration
            abs(sol.dual) * get(duration, sol.constraint_id, 0.0)
        elseif metric == :dual_times_slack_change
            if slack_change === nothing
                continue
            end
            abs(sol.dual) * abs(slack_change)
        else
            _metric_value(metric, sol.dual, slack)
        end
        if value === nothing
            continue
        end
        impact = _impact_label(objective_sense, constraint.sense, sol.dual)
        push!(rows, (
            constraint_id=sol.constraint_id,
            kind=constraint.kind,
            sense=constraint.sense,
            component_ids=constraint.component_ids,
            dual=sol.dual,
            slack=slack,
            metric=value,
            impact=impact,
            time=sol.time,
            scenario=sol.scenario,
        ))
    end

    sort!(rows, by=r -> abs(r.metric), rev=true)
    return rows[1:min(top, length(rows))]
end
