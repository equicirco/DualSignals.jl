using CSV
using Dates
using JSON3

function read_json(path::AbstractString)
    open(path, "r") do io
        return JSON3.read(io, DualSignalsDataset)
    end
end

function write_json(path::AbstractString, dataset::DualSignalsDataset; pretty::Bool=false)
    open(path, "w") do io
        if pretty
            JSON3.write(io, dataset; indent=2)
        else
            JSON3.write(io, dataset)
        end
    end
    return path
end

function to_json_string(dataset::DualSignalsDataset; pretty::Bool=false)
    if pretty
        return JSON3.write(dataset; indent=2)
    end
    return JSON3.write(dataset)
end

function validate_dataset(dataset::DualSignalsDataset; require_units::Bool=false)
    errors = String[]

    if isempty(strip(dataset.dataset_id))
        push!(errors, "dataset_id must be a non-empty string.")
    end

    component_ids = Set{String}()
    for component in dataset.components
        if isempty(strip(component.component_id))
            push!(errors, "component_id must be a non-empty string.")
        elseif component.component_id in component_ids
            push!(errors, "Duplicate component_id: $(component.component_id).")
        else
            push!(component_ids, component.component_id)
        end
    end

    constraint_ids = Set{String}()
    for constraint in dataset.constraints
        if isempty(strip(constraint.constraint_id))
            push!(errors, "constraint_id must be a non-empty string.")
        elseif constraint.constraint_id in constraint_ids
            push!(errors, "Duplicate constraint_id: $(constraint.constraint_id).")
        else
            push!(constraint_ids, constraint.constraint_id)
        end

        if isempty(constraint.component_ids)
            push!(errors, "constraint $(constraint.constraint_id) must reference at least one component_id.")
        else
            for cid in constraint.component_ids
                if !(cid in component_ids)
                    push!(errors, "constraint $(constraint.constraint_id) references missing component_id: $(cid).")
                end
            end
        end
        if require_units && (constraint.unit === nothing || isempty(strip(constraint.unit)))
            push!(errors, "constraint $(constraint.constraint_id) is missing a unit.")
        end
        if constraint.tags !== nothing
            for tag in constraint.tags
                if isempty(strip(tag))
                    push!(errors, "constraint $(constraint.constraint_id) has an empty tag value.")
                end
            end
        end
    end

    for solution in dataset.constraint_solutions
        if !(solution.constraint_id in constraint_ids)
            push!(errors, "constraint_solution references missing constraint_id: $(solution.constraint_id).")
        end
    end

    if dataset.variables !== nothing
        for variable in dataset.variables
            if !(variable.component_id in component_ids)
                push!(errors, "variable_value references missing component_id: $(variable.component_id).")
            end
            if require_units && (variable.unit === nothing || isempty(strip(variable.unit)))
                push!(errors, "variable_value $(variable.name) for $(variable.component_id) is missing a unit.")
            end
        end
    end

    if require_units && (dataset.metadata.units_convention === nothing || isempty(strip(dataset.metadata.units_convention)))
        push!(errors, "metadata.units_convention is required when require_units is enabled.")
    end

    return errors
end

isvalid_dataset(dataset::DualSignalsDataset) = isempty(validate_dataset(dataset))

function write_csv(dataset::DualSignalsDataset, dir::AbstractString; prefix::AbstractString="dualsignals")
    mkpath(dir)

    metadata_row = (
        dataset_id=dataset.dataset_id,
        description=dataset.metadata.description === nothing ? missing : dataset.metadata.description,
        created_at=dataset.metadata.created_at === nothing ? missing : Dates.format(dataset.metadata.created_at, dateformat"yyyy-mm-ddTHH:MM:SS"),
        objective_sense=dataset.metadata.objective_sense === nothing ? missing : string(dataset.metadata.objective_sense),
        objective_value=dataset.metadata.objective_value === nothing ? missing : dataset.metadata.objective_value,
        units_convention=dataset.metadata.units_convention === nothing ? missing : dataset.metadata.units_convention,
        notes=dataset.metadata.notes === nothing ? missing : dataset.metadata.notes,
    )
    CSV.write(joinpath(dir, "$(prefix)_metadata.csv"), [metadata_row])

    component_rows = [
        (
            component_id=c.component_id,
            component_type=string(c.component_type),
            name=c.name === nothing ? missing : c.name,
            parent_id=c.parent_id === nothing ? missing : c.parent_id,
            unit=c.unit === nothing ? missing : c.unit,
            tags=c.tags === nothing ? missing : join(c.tags, ";"),
        ) for c in dataset.components
    ]
    CSV.write(joinpath(dir, "$(prefix)_components.csv"), component_rows)

    constraint_rows = [
        (
            constraint_id=c.constraint_id,
            kind=string(c.kind),
            sense=string(c.sense),
            rhs=c.rhs === nothing ? missing : c.rhs,
            unit=c.unit === nothing ? missing : c.unit,
            component_ids=join(c.component_ids, ";"),
            tags=c.tags === nothing ? missing : join(c.tags, ";"),
        ) for c in dataset.constraints
    ]
    CSV.write(joinpath(dir, "$(prefix)_constraints.csv"), constraint_rows)

    solution_rows = [
        (
            constraint_id=s.constraint_id,
            dual=s.dual,
            activity=s.activity === nothing ? missing : s.activity,
            slack=s.slack === nothing ? missing : s.slack,
            is_binding=s.is_binding === nothing ? missing : s.is_binding,
            time=s.time === nothing ? missing : s.time,
            scenario=s.scenario === nothing ? missing : s.scenario,
        ) for s in dataset.constraint_solutions
    ]
    CSV.write(joinpath(dir, "$(prefix)_constraint_solutions.csv"), solution_rows)

    if dataset.variables !== nothing
        variable_rows = [
            (
                component_id=v.component_id,
                name=v.name,
                value=v.value,
                unit=v.unit === nothing ? missing : v.unit,
                time=v.time === nothing ? missing : v.time,
                scenario=v.scenario === nothing ? missing : v.scenario,
            ) for v in dataset.variables
        ]
        CSV.write(joinpath(dir, "$(prefix)_variables.csv"), variable_rows)
    end

    return dir
end

function _string_or_nothing(x)
    if x === missing || x === nothing
        return nothing
    end
    s = String(x)
    return isempty(strip(s)) ? nothing : s
end

function _float_or_nothing(x)
    if x === missing || x === nothing
        return nothing
    end
    return Float64(x)
end

function _bool_or_nothing(x)
    if x === missing || x === nothing
        return nothing
    end
    return Bool(x)
end

function _split_list(x)
    if x === missing || x === nothing
        return nothing
    end
    s = strip(String(x))
    return isempty(s) ? String[] : split(s, ";")
end

function read_csv(dir::AbstractString; prefix::AbstractString="dualsignals")
    meta_path = joinpath(dir, "$(prefix)_metadata.csv")
    comp_path = joinpath(dir, "$(prefix)_components.csv")
    con_path = joinpath(dir, "$(prefix)_constraints.csv")
    sol_path = joinpath(dir, "$(prefix)_constraint_solutions.csv")
    var_path = joinpath(dir, "$(prefix)_variables.csv")

    metadata_rows = collect(CSV.File(meta_path))
    if isempty(metadata_rows)
        error("metadata CSV is empty: $(meta_path)")
    end
    meta = metadata_rows[1]
    created_at = _string_or_nothing(meta.created_at)
    metadata = DatasetMetadata(
        description=_string_or_nothing(meta.description),
        created_at=created_at === nothing ? nothing : DateTime(created_at),
        objective_sense=_string_or_nothing(meta.objective_sense) === nothing ? nothing :
            _enum_from_string(ObjectiveSense, _string_or_nothing(meta.objective_sense)),
        objective_value=_float_or_nothing(meta.objective_value),
        units_convention=_string_or_nothing(meta.units_convention),
        notes=_string_or_nothing(meta.notes),
    )
    dataset_id = _string_or_nothing(meta.dataset_id)
    if dataset_id === nothing
        error("metadata.dataset_id is required in CSV metadata.")
    end

    components = Component[]
    for row in CSV.File(comp_path)
        tags = _split_list(row.tags)
        push!(components, Component(
            component_id=String(row.component_id),
            component_type=_enum_from_string(ComponentType, String(row.component_type)),
            name=_string_or_nothing(row.name),
            parent_id=_string_or_nothing(row.parent_id),
            unit=_string_or_nothing(row.unit),
            tags=tags === nothing ? nothing : tags,
        ))
    end

    constraints = Constraint[]
    for row in CSV.File(con_path)
        tags = :tags in propertynames(row) ? _split_list(row.tags) : nothing
        component_ids = _split_list(row.component_ids)
        push!(constraints, Constraint(
            constraint_id=String(row.constraint_id),
            kind=_enum_from_string(ConstraintKind, String(row.kind)),
            sense=_enum_from_string(ConstraintSense, String(row.sense)),
            rhs=_float_or_nothing(row.rhs),
            unit=_string_or_nothing(row.unit),
            component_ids=component_ids === nothing ? String[] : component_ids,
            tags=tags === nothing ? nothing : tags,
        ))
    end

    solutions = ConstraintSolution[]
    for row in CSV.File(sol_path)
        push!(solutions, ConstraintSolution(
            constraint_id=String(row.constraint_id),
            dual=Float64(row.dual),
            activity=_float_or_nothing(row.activity),
            slack=_float_or_nothing(row.slack),
            is_binding=_bool_or_nothing(row.is_binding),
            time=_string_or_nothing(row.time),
            scenario=_string_or_nothing(row.scenario),
        ))
    end

    variables = if isfile(var_path)
        vars = VariableValue[]
        for row in CSV.File(var_path)
            push!(vars, VariableValue(
                component_id=String(row.component_id),
                name=String(row.name),
                value=Float64(row.value),
                unit=_string_or_nothing(row.unit),
                time=_string_or_nothing(row.time),
                scenario=_string_or_nothing(row.scenario),
            ))
        end
        vars
    else
        nothing
    end

    return DualSignalsDataset(
        dataset_id=dataset_id,
        metadata=metadata,
        components=components,
        constraints=constraints,
        constraint_solutions=solutions,
        variables=variables,
    )
end

function _require_arrow()
    if Base.find_package("Arrow") === nothing
        error("Arrow.jl is not installed. Run `import Pkg; Pkg.add(\"Arrow\")` to enable Arrow IO.")
    end
    @eval import Arrow
end

function write_arrow(dataset::DualSignalsDataset, dir::AbstractString; prefix::AbstractString="dualsignals")
    _require_arrow()
    mkpath(dir)

    metadata_row = (
        dataset_id=dataset.dataset_id,
        description=dataset.metadata.description === nothing ? missing : dataset.metadata.description,
        created_at=dataset.metadata.created_at === nothing ? missing : Dates.format(dataset.metadata.created_at, dateformat"yyyy-mm-ddTHH:MM:SS"),
        objective_sense=dataset.metadata.objective_sense === nothing ? missing : string(dataset.metadata.objective_sense),
        objective_value=dataset.metadata.objective_value === nothing ? missing : dataset.metadata.objective_value,
        units_convention=dataset.metadata.units_convention === nothing ? missing : dataset.metadata.units_convention,
        notes=dataset.metadata.notes === nothing ? missing : dataset.metadata.notes,
    )
    Arrow.write(joinpath(dir, "$(prefix)_metadata.arrow"), [metadata_row])

    component_rows = [
        (
            component_id=c.component_id,
            component_type=string(c.component_type),
            name=c.name === nothing ? missing : c.name,
            parent_id=c.parent_id === nothing ? missing : c.parent_id,
            unit=c.unit === nothing ? missing : c.unit,
            tags=c.tags === nothing ? missing : join(c.tags, ";"),
        ) for c in dataset.components
    ]
    Arrow.write(joinpath(dir, "$(prefix)_components.arrow"), component_rows)

    constraint_rows = [
        (
            constraint_id=c.constraint_id,
            kind=string(c.kind),
            sense=string(c.sense),
            rhs=c.rhs === nothing ? missing : c.rhs,
            unit=c.unit === nothing ? missing : c.unit,
            component_ids=join(c.component_ids, ";"),
            tags=c.tags === nothing ? missing : join(c.tags, ";"),
        ) for c in dataset.constraints
    ]
    Arrow.write(joinpath(dir, "$(prefix)_constraints.arrow"), constraint_rows)

    solution_rows = [
        (
            constraint_id=s.constraint_id,
            dual=s.dual,
            activity=s.activity === nothing ? missing : s.activity,
            slack=s.slack === nothing ? missing : s.slack,
            is_binding=s.is_binding === nothing ? missing : s.is_binding,
            time=s.time === nothing ? missing : s.time,
            scenario=s.scenario === nothing ? missing : s.scenario,
        ) for s in dataset.constraint_solutions
    ]
    Arrow.write(joinpath(dir, "$(prefix)_constraint_solutions.arrow"), solution_rows)

    if dataset.variables !== nothing
        variable_rows = [
            (
                component_id=v.component_id,
                name=v.name,
                value=v.value,
                unit=v.unit === nothing ? missing : v.unit,
                time=v.time === nothing ? missing : v.time,
                scenario=v.scenario === nothing ? missing : v.scenario,
            ) for v in dataset.variables
        ]
        Arrow.write(joinpath(dir, "$(prefix)_variables.arrow"), variable_rows)
    end

    return dir
end

function read_arrow(dir::AbstractString; prefix::AbstractString="dualsignals")
    _require_arrow()
    meta_path = joinpath(dir, "$(prefix)_metadata.arrow")
    comp_path = joinpath(dir, "$(prefix)_components.arrow")
    con_path = joinpath(dir, "$(prefix)_constraints.arrow")
    sol_path = joinpath(dir, "$(prefix)_constraint_solutions.arrow")
    var_path = joinpath(dir, "$(prefix)_variables.arrow")

    metadata_rows = collect(Arrow.Table(meta_path))
    if isempty(metadata_rows)
        error("metadata Arrow file is empty: $(meta_path)")
    end
    meta = metadata_rows[1]
    created_at = _string_or_nothing(meta.created_at)
    metadata = DatasetMetadata(
        description=_string_or_nothing(meta.description),
        created_at=created_at === nothing ? nothing : DateTime(created_at),
        objective_sense=_string_or_nothing(meta.objective_sense) === nothing ? nothing :
            _enum_from_string(ObjectiveSense, _string_or_nothing(meta.objective_sense)),
        objective_value=_float_or_nothing(meta.objective_value),
        units_convention=_string_or_nothing(meta.units_convention),
        notes=_string_or_nothing(meta.notes),
    )
    dataset_id = _string_or_nothing(meta.dataset_id)
    if dataset_id === nothing
        error("metadata.dataset_id is required in Arrow metadata.")
    end

    components = Component[]
    for row in Arrow.Table(comp_path)
        tags = _split_list(row.tags)
        push!(components, Component(
            component_id=String(row.component_id),
            component_type=_enum_from_string(ComponentType, String(row.component_type)),
            name=_string_or_nothing(row.name),
            parent_id=_string_or_nothing(row.parent_id),
            unit=_string_or_nothing(row.unit),
            tags=tags === nothing ? nothing : tags,
        ))
    end

    constraints = Constraint[]
    for row in Arrow.Table(con_path)
        tags = :tags in propertynames(row) ? _split_list(row.tags) : nothing
        component_ids = _split_list(row.component_ids)
        push!(constraints, Constraint(
            constraint_id=String(row.constraint_id),
            kind=_enum_from_string(ConstraintKind, String(row.kind)),
            sense=_enum_from_string(ConstraintSense, String(row.sense)),
            rhs=_float_or_nothing(row.rhs),
            unit=_string_or_nothing(row.unit),
            component_ids=component_ids === nothing ? String[] : component_ids,
            tags=tags === nothing ? nothing : tags,
        ))
    end

    solutions = ConstraintSolution[]
    for row in Arrow.Table(sol_path)
        push!(solutions, ConstraintSolution(
            constraint_id=String(row.constraint_id),
            dual=Float64(row.dual),
            activity=_float_or_nothing(row.activity),
            slack=_float_or_nothing(row.slack),
            is_binding=_bool_or_nothing(row.is_binding),
            time=_string_or_nothing(row.time),
            scenario=_string_or_nothing(row.scenario),
        ))
    end

    variables = if isfile(var_path)
        vars = VariableValue[]
        for row in Arrow.Table(var_path)
            push!(vars, VariableValue(
                component_id=String(row.component_id),
                name=String(row.name),
                value=Float64(row.value),
                unit=_string_or_nothing(row.unit),
                time=_string_or_nothing(row.time),
                scenario=_string_or_nothing(row.scenario),
            ))
        end
        vars
    else
        nothing
    end

    return DualSignalsDataset(
        dataset_id=dataset_id,
        metadata=metadata,
        components=components,
        constraints=constraints,
        constraint_solutions=solutions,
        variables=variables,
    )
end
