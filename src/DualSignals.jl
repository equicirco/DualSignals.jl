module DualSignals

using Dates
using JSON3
using StructTypes

include("datamodel/schema.jl")
include("datamodel/io.jl")
include("analysis/impact.jl")
include("analysis/bindingness.jl")
include("analysis/rankings.jl")
include("analysis/aggregation.jl")
include("reporting/tables.jl")
include("reporting/narratives.jl")
include("adapter/jump.jl")

export DualSignalsDataset,
    DatasetMetadata,
    Component,
    Constraint,
    ConstraintSolution,
    VariableValue,
    ObjectiveSense,
    ComponentType,
    ConstraintKind,
    ConstraintSense,
    read_json,
    write_json,
    to_json_string,
    read_csv,
    write_csv,
    read_arrow,
    write_arrow,
    validate_dataset,
    isvalid_dataset,
    bindingness,
    rank_constraints,
    aggregate_duals,
    aggregate_duals_series,
    table_top_constraints,
    table_policy_priorities,
    narrative_top_bottlenecks,
    narrative_policy_summary,
    jump_dataset

end
