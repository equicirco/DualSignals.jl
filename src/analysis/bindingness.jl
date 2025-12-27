function _infer_slack(constraint::Constraint, solution::ConstraintSolution)
    if solution.slack !== nothing
        return solution.slack
    end
    if solution.activity === nothing || constraint.rhs === nothing
        return nothing
    end
    if constraint.sense == DualSignals.le
        return constraint.rhs - solution.activity
    elseif constraint.sense == DualSignals.ge
        return solution.activity - constraint.rhs
    end
    return abs(solution.activity - constraint.rhs)
end

function _infer_binding(constraint::Constraint, solution::ConstraintSolution, tol::Float64)
    if solution.is_binding !== nothing
        return solution.is_binding
    end
    slack = _infer_slack(constraint, solution)
    if slack === nothing
        return nothing
    end
    return abs(slack) <= tol
end


function bindingness(dataset::DualSignalsDataset; tol::Float64=1e-6)
    constraints = Dict(c.constraint_id => c for c in dataset.constraints)
    rows = Vector{NamedTuple}()
    objective_sense = dataset.metadata.objective_sense

    for sol in dataset.constraint_solutions
        constraint = get(constraints, sol.constraint_id, nothing)
        if constraint === nothing
            continue
        end
        slack = _infer_slack(constraint, sol)
        is_binding = _infer_binding(constraint, sol, tol)
        impact = _impact_label(objective_sense, constraint.sense, sol.dual)
        push!(rows, (
            constraint_id=sol.constraint_id,
            kind=constraint.kind,
            sense=constraint.sense,
            rhs=constraint.rhs,
            activity=sol.activity,
            slack=slack,
            dual=sol.dual,
            is_binding=is_binding,
            impact=impact,
            time=sol.time,
            scenario=sol.scenario,
        ))
    end

    return rows
end
