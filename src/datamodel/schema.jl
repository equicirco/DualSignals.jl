using Dates
using StructTypes

@enum ObjectiveSense minimize maximize
@enum ComponentType node link source sink sector product agent other
@enum ConstraintKind balance capacity resource policy_cap technology other
@enum ConstraintSense le eq ge

StructTypes.StructType(::Type{ObjectiveSense}) = StructTypes.StringType()
StructTypes.StructType(::Type{ComponentType}) = StructTypes.StringType()
StructTypes.StructType(::Type{ConstraintKind}) = StructTypes.StringType()
StructTypes.StructType(::Type{ConstraintSense}) = StructTypes.StringType()

StructTypes.StructType(::Type{DateTime}) = StructTypes.StringType()

function StructTypes.construct(::Type{DateTime}, x)
    if x isa DateTime
        return x
    end
    if x isa AbstractString
        return DateTime(x)
    end
    error("Invalid DateTime value: $(repr(x))")
end

StructTypes.lower(x::DateTime) = Dates.format(x, dateformat"yyyy-mm-ddTHH:MM:SS")

function _enum_from_string(::Type{T}, x) where {T}
    if x isa Symbol
        x = String(x)
    end
    if x isa AbstractString
        for val in Base.Enums.instances(T)
            if x == string(val)
                return val
            end
        end
    end
    error("Invalid $(T) value: $(repr(x))")
end

function StructTypes.construct(::Type{ObjectiveSense}, x)
    return _enum_from_string(ObjectiveSense, x)
end

function StructTypes.construct(::Type{ComponentType}, x)
    return _enum_from_string(ComponentType, x)
end

function StructTypes.construct(::Type{ConstraintKind}, x)
    return _enum_from_string(ConstraintKind, x)
end

function StructTypes.construct(::Type{ConstraintSense}, x)
    return _enum_from_string(ConstraintSense, x)
end

StructTypes.lower(x::ObjectiveSense) = string(x)
StructTypes.lower(x::ComponentType) = string(x)
StructTypes.lower(x::ConstraintKind) = string(x)
StructTypes.lower(x::ConstraintSense) = string(x)

Base.@kwdef struct DatasetMetadata
    description::Union{String,Nothing} = nothing
    created_at::Union{DateTime,Nothing} = nothing
    objective_sense::Union{ObjectiveSense,Nothing} = nothing
    objective_value::Union{Float64,Nothing} = nothing
    units_convention::Union{String,Nothing} = nothing
    notes::Union{String,Nothing} = nothing
end

Base.@kwdef struct Component
    component_id::String
    component_type::ComponentType
    name::Union{String,Nothing} = nothing
    parent_id::Union{String,Nothing} = nothing
    unit::Union{String,Nothing} = nothing
    tags::Union{Vector{String},Nothing} = nothing
end

Base.@kwdef struct Constraint
    constraint_id::String
    kind::ConstraintKind
    sense::ConstraintSense
    rhs::Union{Float64,Nothing} = nothing
    unit::Union{String,Nothing} = nothing
    component_ids::Vector{String}
end

Base.@kwdef struct ConstraintSolution
    constraint_id::String
    dual::Float64
    activity::Union{Float64,Nothing} = nothing
    slack::Union{Float64,Nothing} = nothing
    is_binding::Union{Bool,Nothing} = nothing
    time::Union{String,Nothing} = nothing
    scenario::Union{String,Nothing} = nothing
end

Base.@kwdef struct VariableValue
    component_id::String
    name::String
    value::Float64
    unit::Union{String,Nothing} = nothing
    time::Union{String,Nothing} = nothing
    scenario::Union{String,Nothing} = nothing
end

Base.@kwdef struct DualSignalsDataset
    dataset_id::String
    metadata::DatasetMetadata
    components::Vector{Component}
    constraints::Vector{Constraint}
    constraint_solutions::Vector{ConstraintSolution}
    variables::Union{Vector{VariableValue},Nothing} = nothing
end

StructTypes.StructType(::Type{DatasetMetadata}) = StructTypes.Struct()
StructTypes.StructType(::Type{Component}) = StructTypes.Struct()
StructTypes.StructType(::Type{Constraint}) = StructTypes.Struct()
StructTypes.StructType(::Type{ConstraintSolution}) = StructTypes.Struct()
StructTypes.StructType(::Type{VariableValue}) = StructTypes.Struct()
StructTypes.StructType(::Type{DualSignalsDataset}) = StructTypes.Struct()
