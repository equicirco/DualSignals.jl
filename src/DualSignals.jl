module DualSignals

using Dates
using JSON3
using StructTypes

include("datamodel/schema.jl")
include("datamodel/io.jl")

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
    validate_dataset,
    isvalid_dataset

end
