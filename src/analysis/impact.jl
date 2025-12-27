function _impact_label(objective_sense, sense::ConstraintSense, dual::Float64)
    if objective_sense === nothing
        return "impact depends on objective sense"
    end
    direction = objective_sense == DualSignals.minimize ? dual : -dual
    if sense == DualSignals.le
        return direction >= 0 ? "increasing RHS reduces objective" : "increasing RHS increases objective"
    elseif sense == DualSignals.ge
        return direction >= 0 ? "decreasing RHS reduces objective" : "decreasing RHS increases objective"
    end
    return direction >= 0 ? "relaxing equality reduces objective" : "relaxing equality increases objective"
end
