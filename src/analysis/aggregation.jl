using Statistics

"""
Aggregate dual values by constraint kind, id, or component id.

Keywords:
- `by`: `:kind`, `:constraint_id`, or `:component_id`.
- `scenario`: optional scenario filter.
- `time`: optional time filter.

Returns a vector of named tuples with `key`, `count`, `mean`, `mean_abs`, and `max_abs`.
"""
function aggregate_duals(
    dataset::DualSignalsDataset;
    by::Symbol=:kind,
    scenario=nothing,
    time=nothing,
)
    constraints = Dict(c.constraint_id => c for c in dataset.constraints)
    bucket = Dict{Any, Vector{Float64}}()

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
        key = if by == :kind
            constraint.kind
        elseif by == :constraint_id
            sol.constraint_id
        elseif by == :component_id
            isempty(constraint.component_ids) ? "unknown" : constraint.component_ids[1]
        else
            error("Unknown aggregation key: $(by)")
        end
        values = get!(bucket, key, Float64[])
        push!(values, sol.dual)
    end

    rows = Vector{NamedTuple}()
    for (key, values) in bucket
        push!(rows, (
            key=key,
            count=length(values),
            mean=mean(values),
            mean_abs=mean(abs.(values)),
            max_abs=maximum(abs.(values)),
        ))
    end

    sort!(rows, by=r -> r.max_abs, rev=true)
    return rows
end

"""
Aggregate dual values over time or scenario for each key.

Keywords:
- `by`: `:constraint_id`, `:kind`, or `:component_id`.
- `over`: `:time` or `:scenario`.
- `scenario`: optional scenario filter.

Returns a vector of named tuples with `key`, `over`, `count`, `mean`, `mean_abs`, and `max_abs`.
"""
function aggregate_duals_series(
    dataset::DualSignalsDataset;
    by::Symbol=:constraint_id,
    over::Symbol=:time,
    scenario=nothing,
)
    constraints = Dict(c.constraint_id => c for c in dataset.constraints)
    bucket = Dict{Tuple{Any, Any}, Vector{Float64}}()

    for sol in dataset.constraint_solutions
        if scenario !== nothing && sol.scenario != scenario
            continue
        end
        constraint = get(constraints, sol.constraint_id, nothing)
        if constraint === nothing
            continue
        end
        key = if by == :constraint_id
            sol.constraint_id
        elseif by == :kind
            constraint.kind
        elseif by == :component_id
            isempty(constraint.component_ids) ? "unknown" : constraint.component_ids[1]
        else
            error("Unknown aggregation key: $(by)")
        end
        over_value = if over == :time
            sol.time
        elseif over == :scenario
            sol.scenario
        else
            error("Unknown aggregation dimension: $(over)")
        end
        values = get!(bucket, (key, over_value), Float64[])
        push!(values, sol.dual)
    end

    rows = Vector{NamedTuple}()
    for ((key, over_value), values) in bucket
        push!(rows, (
            key=key,
            over=over_value,
            count=length(values),
            mean=mean(values),
            mean_abs=mean(abs.(values)),
            max_abs=maximum(abs.(values)),
        ))
    end

    sort!(rows, by=r -> (string(r.key), string(r.over)))
    return rows
end
