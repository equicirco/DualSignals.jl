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

function validate_dataset(dataset::DualSignalsDataset)
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
        end
    end

    return errors
end

isvalid_dataset(dataset::DualSignalsDataset) = isempty(validate_dataset(dataset))
