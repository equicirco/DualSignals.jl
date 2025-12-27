---
title: Data IO
nav_order: 3
---

# Data IO

The Julia package includes lightweight IO utilities for reading and writing
DualSignals datasets as JSON, plus a simple validator for consistency checks.

## Functions

### `read_json(path)`
Reads a JSON file into a `DualSignalsDataset` using JSON3/StructTypes mappings.

### `write_json(path, dataset; pretty=false)`
Writes a dataset to a JSON file. Use `pretty=true` for human-readable output.

### `to_json_string(dataset; pretty=false)`
Returns a JSON string for a dataset (useful for tests or API responses).

### `validate_dataset(dataset)`
Returns a vector of error strings for:
- empty `dataset_id`
- duplicate component or constraint IDs
- constraints with no `component_ids`
- references to missing component or constraint IDs

### `isvalid_dataset(dataset)`
Convenience wrapper that returns `true` if `validate_dataset` returns no errors.

## Example

```julia
using DualSignals

dataset = DualSignalsDataset(
    dataset_id="demo",
    metadata=DatasetMetadata(description="simple example"),
    components=[
        Component(component_id="n1", component_type=DualSignals.node)
    ],
    constraints=[
        Constraint(
            constraint_id="c1",
            kind=DualSignals.balance,
            sense=DualSignals.eq,
            component_ids=["n1"],
        )
    ],
    constraint_solutions=[
        ConstraintSolution(constraint_id="c1", dual=1.0)
    ],
    variables=nothing,
)

errors = validate_dataset(dataset)
@assert isempty(errors)

write_json("dualsignals.json", dataset; pretty=true)
loaded = read_json("dualsignals.json")
```
