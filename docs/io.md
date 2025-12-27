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

### `write_csv(dataset, dir; prefix="dualsignals")`
Writes a dataset into a directory as multiple CSV files:

- `dualsignals_metadata.csv`
- `dualsignals_components.csv`
- `dualsignals_constraints.csv`
- `dualsignals_constraint_solutions.csv`
- `dualsignals_variables.csv` (if present)

### `read_csv(dir; prefix="dualsignals")`
Reads the CSV directory produced by `write_csv` and reconstructs a dataset.
Constraint and component tags are stored in the CSV as `tags` columns with
semicolon-delimited lists.

### Optional Arrow IO

Arrow support is available if you install `Arrow.jl`:

```julia
import Pkg
Pkg.add("Arrow")
```

Functions:

### `write_arrow(dataset, dir; prefix="dualsignals")`
Writes Arrow IPC files (`.arrow`) for metadata, components, constraints,
constraint solutions, and variables.

### `read_arrow(dir; prefix="dualsignals")`
Reads the Arrow IPC files produced by `write_arrow`.

### `validate_dataset(dataset; require_units=false)`
Returns a vector of error strings for:
- empty `dataset_id`
- duplicate component or constraint IDs
- constraints with no `component_ids`
- references to missing component or constraint IDs
- missing units (when `require_units=true`)

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
