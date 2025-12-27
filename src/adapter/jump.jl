using JuMP
import MathOptInterface as MOI

function _var_id(var::JuMP.VariableRef)
    name = JuMP.name(var)
    if name == ""
        return "var_$(JuMP.index(var).value)"
    end
    return name
end

function _constraint_id(cref::JuMP.ConstraintRef)
    name = JuMP.name(cref)
    if name == ""
        return "con_$(JuMP.index(cref).value)"
    end
    return name
end

function _constraint_label(cref::JuMP.ConstraintRef)
    name = JuMP.name(cref)
    return name == "" ? _constraint_id(cref) : name
end

function _default_kind_hint(label::AbstractString)
    text = lowercase(label)
    if occursin("balance", text) || occursin("kcl", text) || occursin("flow_balance", text)
        return DualSignals.balance
    elseif occursin("cap", text) || occursin("limit", text) || occursin("bound", text)
        return DualSignals.capacity
    elseif occursin("resource", text)
        return DualSignals.resource
    elseif occursin("policy", text) || occursin("emission", text)
        return DualSignals.policy_cap
    elseif occursin("tech", text)
        return DualSignals.technology
    end
    return DualSignals.other
end

function _default_tag_hint(label::AbstractString, kind::ConstraintKind)
    return nothing
end

function _component_map(model::JuMP.Model)
    components = Component[]
    seen = Set{String}()
    for var in all_variables(model)
        cid = _var_id(var)
        if cid in seen
            continue
        end
        push!(components, Component(component_id=cid, component_type=DualSignals.other, name=cid))
        push!(seen, cid)
    end
    return components
end

function _constraint_components(func)
    vars = JuMP.all_variables(func)
    ids = [_var_id(v) for v in vars]
    return isempty(ids) ? ["scalar"] : unique(ids)
end

function _sense_and_rhs(set)
    if set isa MOI.LessThan
        return DualSignals.le, set.upper
    elseif set isa MOI.GreaterThan
        return DualSignals.ge, set.lower
    elseif set isa MOI.EqualTo
        return DualSignals.eq, set.value
    end
    return nothing, nothing
end

function _activity_value(func)
    try
        return JuMP.value(func)
    catch
        return nothing
    end
end

function jump_dataset(
    model::JuMP.Model;
    dataset_id::AbstractString="jump_model",
    include_variables::Bool=true,
    include_constraints::Bool=true,
    include_constraint_solutions::Bool=true,
    units_convention::Union{String,Nothing}=nothing,
    description::Union{String,Nothing}=nothing,
    kind_hint::Function=_default_kind_hint,
    tag_hint::Function=_default_tag_hint,
)
    components = _component_map(model)
    constraints = Constraint[]
    solutions = ConstraintSolution[]
    variables = include_variables ? VariableValue[] : nothing
    needs_scalar = false

    if include_constraints || include_constraint_solutions
        for (F, S) in JuMP.list_of_constraint_types(model)
            for cref in JuMP.all_constraints(model, F, S)
                obj = JuMP.constraint_object(cref)
                sense, rhs = _sense_and_rhs(obj.set)
                if sense === nothing
                    continue
                end
                cid = _constraint_id(cref)
                label = _constraint_label(cref)
                kind = kind_hint(label)
                tags = tag_hint(label, kind)
                component_ids = _constraint_components(obj.func)
                if component_ids == ["scalar"]
                    needs_scalar = true
                end
                if include_constraints
                    push!(constraints, Constraint(
                        constraint_id=cid,
                        kind=kind,
                        sense=sense,
                        rhs=rhs,
                        unit=nothing,
                        component_ids=component_ids,
                        tags=tags,
                    ))
                end
                if include_constraint_solutions
                    dual = try
                        JuMP.dual(cref)
                    catch
                        nothing
                    end
                    if dual !== nothing
                        activity = _activity_value(obj.func)
                        push!(solutions, ConstraintSolution(
                            constraint_id=cid,
                            dual=Float64(dual),
                            activity=activity,
                            slack=nothing,
                            is_binding=nothing,
                            time=nothing,
                            scenario=nothing,
                        ))
                    end
                end
            end
        end
    end

    if include_variables
        for var in all_variables(model)
            value = try
                JuMP.value(var)
            catch
                nothing
            end
            if value === nothing
                continue
            end
            push!(variables, VariableValue(
                component_id=_var_id(var),
                name="value",
                value=Float64(value),
                unit=nothing,
                time=nothing,
                scenario=nothing,
            ))
        end
    end

    if needs_scalar && all(c.component_id != "scalar" for c in components)
        push!(components, Component(component_id="scalar", component_type=DualSignals.other, name="Scalar"))
    end

    obj_sense = JuMP.objective_sense(model)
    objective_sense = if obj_sense == MOI.MIN_SENSE
        DualSignals.minimize
    elseif obj_sense == MOI.MAX_SENSE
        DualSignals.maximize
    else
        nothing
    end

    metadata = DatasetMetadata(
        description=description,
        created_at=nothing,
        objective_sense=objective_sense,
        objective_value=try
            JuMP.objective_value(model)
        catch
            nothing
        end,
        units_convention=units_convention,
        notes="Generated from JuMP model; constraint kinds inferred from names.",
    )

    return DualSignalsDataset(
        dataset_id=String(dataset_id),
        metadata=metadata,
        components=components,
        constraints=constraints,
        constraint_solutions=solutions,
        variables=variables,
    )
end
