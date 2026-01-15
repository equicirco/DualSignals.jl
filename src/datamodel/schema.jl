using Dates
using StructTypes

"""
Objective sense for interpreting dual impacts.

- `minimize`: duals are interpreted directly.
- `maximize`: duals are interpreted with reversed sign.
"""
@enum ObjectiveSense minimize maximize

"""
High-level category for model components.
"""
@enum ComponentType node link source sink sector product agent other

"""
High-level category for constraints.

- `balance`: flow or nodal balance.
- `capacity`: upper/lower bounds or limits.
- `resource`: resource availability constraints.
- `policy_cap`: policy-driven caps (emissions, quotas).
- `technology`: technology-driven bounds.
"""
@enum ConstraintKind balance capacity resource policy_cap technology other_constraint

"""
Constraint sense (<=, =, >=).

- `le`: less-than-or-equal
- `eq`: equality
- `ge`: greater-than-or-equal
"""
@enum ConstraintSense le eq ge

StructTypes.StructType(::Type{ObjectiveSense}) = StructTypes.StringType()
StructTypes.StructType(::Type{ComponentType}) = StructTypes.StringType()
StructTypes.StructType(::Type{ConstraintKind}) = StructTypes.StringType()
StructTypes.StructType(::Type{ConstraintSense}) = StructTypes.StringType()

StructTypes.StructType(::Type{DateTime}) = StructTypes.StringType()

StructTypes.construct(::Type{DateTime}, x::DateTime) = x
StructTypes.construct(::Type{DateTime}, x::String) = DateTime(x)

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

function _enum_from_string(::Type{ConstraintKind}, x)
    if x isa Symbol
        x = String(x)
    end
    if x isa AbstractString
        if x == "other"
            return other_constraint
        end
        for val in Base.Enums.instances(ConstraintKind)
            if x == string(val)
                return val
            end
        end
    end
    error("Invalid $(ConstraintKind) value: $(repr(x))")
end

StructTypes.construct(::Type{ObjectiveSense}, x::AbstractString) =
    _enum_from_string(ObjectiveSense, x)
StructTypes.construct(::Type{ObjectiveSense}, x::Symbol) =
    _enum_from_string(ObjectiveSense, String(x))

StructTypes.construct(::Type{ComponentType}, x::AbstractString) =
    _enum_from_string(ComponentType, x)
StructTypes.construct(::Type{ComponentType}, x::Symbol) =
    _enum_from_string(ComponentType, String(x))

StructTypes.construct(::Type{ConstraintKind}, x::AbstractString) =
    _enum_from_string(ConstraintKind, x)
StructTypes.construct(::Type{ConstraintKind}, x::Symbol) =
    _enum_from_string(ConstraintKind, String(x))

StructTypes.construct(::Type{ConstraintSense}, x::AbstractString) =
    _enum_from_string(ConstraintSense, x)
StructTypes.construct(::Type{ConstraintSense}, x::Symbol) =
    _enum_from_string(ConstraintSense, String(x))

StructTypes.lower(x::ObjectiveSense) = string(x)
StructTypes.lower(x::ComponentType) = string(x)
StructTypes.lower(x::ConstraintKind) = x == other_constraint ? "other" : string(x)
StructTypes.lower(x::ConstraintSense) = string(x)

"""
Metadata describing the dataset and objective context.

Fields:
- `description`: optional description of the dataset.
- `created_at`: optional timestamp for when the dataset was generated.
- `objective_sense`: `minimize` or `maximize` if known.
- `objective_value`: objective value at the solution if known.
- `units_convention`: optional units description (e.g., "MW, USD/MWh").
- `notes`: free-form notes for provenance and assumptions.
"""
Base.@kwdef struct DatasetMetadata
    description::Union{String,Nothing} = nothing
    created_at::Union{DateTime,Nothing} = nothing
    objective_sense::Union{ObjectiveSense,Nothing} = nothing
    objective_value::Union{Float64,Nothing} = nothing
    units_convention::Union{String,Nothing} = nothing
    notes::Union{String,Nothing} = nothing
end

"""
Component in the model (node, link, sector, etc.).

`component_id` should be unique within a dataset.
"""
Base.@kwdef struct Component
    component_id::String
    component_type::ComponentType
    name::Union{String,Nothing} = nothing
    parent_id::Union{String,Nothing} = nothing
    unit::Union{String,Nothing} = nothing
    tags::Union{Vector{String},Nothing} = nothing
end

"""
Constraint metadata with sense, kind, and component references.

`component_ids` should refer to `Component.component_id` values.
"""
Base.@kwdef struct Constraint
    constraint_id::String
    kind::ConstraintKind
    sense::ConstraintSense
    rhs::Union{Float64,Nothing} = nothing
    unit::Union{String,Nothing} = nothing
    component_ids::Vector{String}
    tags::Union{Vector{String},Nothing} = nothing
end

"""
Solution record for a constraint, including dual and optional slack/activity.

`dual` is required; `activity`, `slack`, and `is_binding` are optional.
"""
Base.@kwdef struct ConstraintSolution
    constraint_id::String
    dual::Float64
    activity::Union{Float64,Nothing} = nothing
    slack::Union{Float64,Nothing} = nothing
    is_binding::Union{Bool,Nothing} = nothing
    time::Union{String,Nothing} = nothing
    scenario::Union{String,Nothing} = nothing
end

"""
Value of a variable associated with a component.

`name` identifies the variable (e.g., "flow", "production", "value").
"""
Base.@kwdef struct VariableValue
    component_id::String
    name::String
    value::Float64
    unit::Union{String,Nothing} = nothing
    time::Union{String,Nothing} = nothing
    scenario::Union{String,Nothing} = nothing
end

"""
Top-level dataset containing metadata, components, constraints, and solutions.

`dataset_id` should be unique for storage or exchange.
"""
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
